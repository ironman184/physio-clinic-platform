# Generic Approach for Reverse Engineering / Cryptanalysis Tasks

## Overview
This document provides a reusable approach for security reverse engineering tasks (checksums, MACs, session ID generators, protocol analysis) based on successful solutions to multiple Dynamo tasks.

---

## 1. CRITICAL RULES: No Hardcoding & No Famous Constants

### ❌ WRONG - Hardcoded Lists Containing the Answer
```python
# BAD: Pre-seeded lists that start with or contain the exact answer
common_multipliers = [1664525, 1103515245, 134775813]  # If 1664525 is the answer
common_rotations = [(5, 13), (7, 17), (3, 11)]         # If (5,13) is the answer
c_candidates = [1013904223, 2531011, 6364136223]       # If first one is the answer
```

**Why this is cheating:**
- The answer is pre-seeded in position 0 or early in the list
- This proves nothing about uniqueness or genuine recovery
- Models/agents can accidentally "leak" ground truth into candidate lists

### ❌ WRONG - Using Famous Constants (Enables Catalog Sweeping)
```python
# BAD: Ground truth uses recognizable constants
INIT = 0xDEADBEEF           # Famous hex pattern - models know this
COEFF_A = 0x9E3779B9        # Golden ratio fractional part - well known
COEFF_B = 0x61C88647        # Inverse golden ratio - well known
POLYNOMIAL = 0x104C11DB7    # CRC-32 Ethernet - extremely famous

# BAD: Oracle tests these famous constants first
coefficient_candidates = [
    (0x9E3779B9, 0x61C88647),  # Golden ratio pair - if this is the answer!
    (0x6C078965, 0x7F4A7C15),  # Other well-known
    # ... then random
]
```

**Why this fails hardening:**
- Stronger models can succeed by **catalog sweeping** - trying famous constant combinations
- "One lucky CRC-poly-plus-golden-ratio hypothesis" could clear pass@5
- Not testing genuine cryptanalysis - just testing recall of published constants
- Even if you claim "exhaustive search", using famous constants undermines the task

### ✅ CORRECT - Exhaustive or Mathematically-Derived Ranges
```python
# GOOD: Test ALL values in a range
for mult in range(1, 256, 2):           # ALL 128 odd multipliers
    for rot in range(8):                 # ALL rotation values 0-7
        for xor_const in range(256):     # ALL XOR constants

# GOOD: Systematically derived from mathematical principles
def generate_candidates():
    import math
    candidates = set()
    
    # Derive from well-known constants (golden ratio, e, pi, etc.)
    constants = [
        ('phi', (1 + math.sqrt(5)) / 2),
        ('e', math.e),
        ('pi', math.pi),
    ]
    
    for name, value in constants:
        frac = value - int(value)
        c32 = int(frac * (2**32)) & 0xFFFFFFFF
        candidates.add(c32)
        candidates.add((~c32) & 0xFFFFFFFF)  # Complement
    
    # Add standard crypto constants from known algorithms
    candidates.add(0x5A827999)  # SHA-1
    candidates.add(0x6ED9EBA1)  # SHA-1
    
    return sorted(candidates)

# GOOD: Exhaustive enumeration of small spaces
for r1 in range(1, 32):      # All rotation pairs for 32-bit words
    for r2 in range(1, 32):
        # Test this combination...
```

### ✅ BETTER - Algebraic Solving (When Possible)
```python
# BEST: Derive parameters algebraically instead of searching
def solve_coefficients_algebraically(poly, sbox_params, init, single_samples):
    """
    For linear recurrences like: tag = (INIT * A XOR sbox) * B
    
    Given two samples with different sbox outputs:
    - tag1 = (INIT * A XOR sbox1) * B
    - tag2 = (INIT * A XOR sbox2) * B
    
    Taking XOR difference eliminates common terms:
    - tag1 XOR tag2 = (sbox1 XOR sbox2) * B
    
    Solve for B using field division:
    - B = (tag1 XOR tag2) / (sbox1 XOR sbox2)  [in GF(2^32)]
    
    Then back-substitute to find A.
    """
    # Get two different samples
    b1, b2 = sorted(single_samples.keys())[:2]
    tag1, tag2 = single_samples[b1], single_samples[b2]
    
    # Compute S-box outputs
    sbox1 = parametric_sbox(b1, *sbox_params)
    sbox2 = parametric_sbox(b2, *sbox_params)
    
    # Algebraic solving
    sbox_diff = sbox1 ^ sbox2
    if sbox_diff == 0:
        return None  # Can't divide by zero
    
    tag_diff = tag1 ^ tag2
    coeff_b = gf32_div(tag_diff, sbox_diff, poly)  # Field division
    
    # Back-solve for A
    intermediate = gf32_div(tag1, coeff_b, poly)
    coeff_a = gf32_div(intermediate ^ sbox1, init, poly)
    
    # Validate against ALL samples
    for byte_val, expected_tag in single_samples.items():
        sbox_val = parametric_sbox(byte_val, *sbox_params)
        state = gf32_mult(init, coeff_a, poly) ^ sbox_val
        computed = gf32_mult(state, coeff_b, poly)
        if computed != expected_tag:
            return None  # Algebraic solution doesn't match - wrong S-box
    
    return (coeff_a, coeff_b)

# CRITICAL: This replaces searching through candidate coefficient pairs!
# No famous constants needed - coefficients are DERIVED from samples
```

### ✅ HYBRID APPROACH - Standard Components + Bespoke Parameters
```python
# ACCEPTABLE: Use standard/famous constants for SOME components IF:
# 1. Other components are genuinely bespoke (random, no prior art)
# 2. The bespoke components require algebraic solving
# 3. The standard component is the ONLY reasonable choice (e.g., CRC-32 for GF(2^32))

# Example: CRC-32 polynomial + algebraically-solved random coefficients
POLYNOMIAL_CANDIDATES = [
    0x104C11DB7,  # CRC-32 Ethernet (standard, but only ~10 to test)
    0x1EDC6F41,   # CRC-32C
    # ... 8 more standard GF(2^32) polynomials
]

# Generate RANDOM bespoke parameters (run once, save to file)
import secrets
params = {
    'polynomial': 0x104C11DB7,  # Standard (acceptable)
    'sbox_mult': secrets.choice([m for m in range(1, 256, 2)]),  # RANDOM odd
    'sbox_rot': secrets.randbelow(8),                             # RANDOM 0-7
    'sbox_xor': secrets.randbelow(256),                           # RANDOM 0-255
    'coeff_a': secrets.randbelow(2**32) | 1,                      # RANDOM odd
    'coeff_b': secrets.randbelow(2**32) | 1,                      # RANDOM odd
    'init': secrets.randbelow(2**32)                              # RANDOM
}

# Oracle must:
# 1. Test ~10 standard polynomials (exhaustive small set)
# 2. Exhaustively search S-box space (262K combinations)
# 3. ALGEBRAICALLY DERIVE coefficients (not search candidate list!)

# Result: No catalog sweeping possible - models can't guess random values
```

**Key Principle:** If the ground truth value appears in your candidate list, it should be because:
1. You're testing ALL possible values exhaustively, OR
2. It's a standard component from a small set (10 polynomials, not 1000), AND other components are bespoke, OR
3. **IT'S DERIVED ALGEBRAICALLY** - coefficients solved from field equations, not guessed

**NOT because:**
- ❌ You know it's the answer and put it first
- ❌ It's a famous constant (golden ratio, 0xDEADBEEF) that models can recall
- ❌ You're testing "common" values that happen to include the answer

---

## 2. CRITICAL: Held-Out Test Data Must Be TRULY Held-Out

### ❌ WRONG - "Held-Out" Tests That Are Actually In Training
```python
# In samples.jsonl (training data):
{"firmware_hex": "000102...95", "tag": 2762911996}  # 150 bytes
{"firmware_hex": "000102...c7", "tag": 1296584358}  # 200 bytes

# In test_outputs.py (claimed held-out):
HELD_OUT = [
    ("000102...95", 2762911996),  # 150 bytes - SAME AS TRAINING!
    ("000102...c7", 1296584358),  # 200 bytes - SAME AS TRAINING!
]

# In task.toml:
verification_explanation = "...held-out (firmware, tag) pairs NOT in training data..."
```

**Why this fails verification:**
- **verification_explanation_quality (FAIL)** - Documentation claims samples are NOT in training, but they ARE
- **anti_cheat (weak)** - Agent can pass by simple lookup/memorization instead of genuine recovery
- If all "held-out" tests are actually in training, the task tests nothing

### ✅ CORRECT - Genuinely Held-Out Test Data
```python
# In samples.jsonl (training data):
# - Empty sample
# - Single bytes: 0x00-0x1F (32 values)
# - Two-byte patterns: 0x0000, 0x0101, 0x1010, etc.
# - Multi-byte up to 128 bytes maximum
# Total: 65 samples, max length 128 bytes

# In test_outputs.py (TRULY held-out):
HELD_OUT = [
    ("20", 3827718941),    # Single byte 0x20 - NOT in training (which has 0x00-0x1F)
    ("42", 3985733718),    # Single byte 0x42 - NOT in training
    
    # Long sequences BEYOND training maximum (128 bytes)
    ("000102...95", 2762911996),  # 150 bytes - LONGER than any training sample
    ("000102...c7", 1296584358),  # 200 bytes - LONGER than any training sample
    ("000102...f9", 1480829296),  # 250 bytes - LONGER than any training sample
    ("000102...ff", 3444057713),  # 256 bytes - LONGER than any training sample (spec max)
]

# In task.toml:
verification_explanation = "...6 held-out (firmware, tag) pairs NOT in training data, including single bytes not in training (0x20, 0x42) testing S-box extrapolation beyond the 0x00-0x1F training set, and long extrapolations (150, 200, 250, 256 bytes) beyond 128-byte training maximum..."
```

**Why this passes:**
- ✅ All test vectors are genuinely NOT in training data
- ✅ Tests extrapolation beyond training range (both byte values and lengths)
- ✅ Prevents lookup-table memorization
- ✅ Documentation accurately describes what's held-out
- ✅ Forces genuine algorithm recovery

### Implementation Steps
```bash
# 1. Generate full training data (including long samples)
python generate_samples.py  # Creates 69 samples

# 2. Remove specific samples you want held-out
cd environment/data
# Remove 150/200/250/256-byte samples from samples.jsonl
# Keep them ONLY in test_outputs.py

# 3. Verify removal
wc -l samples.jsonl  # Should be 65 (was 69)
grep "2762911996" samples.jsonl  # Should return nothing

# 4. Update documentation
# - task.toml: verification_explanation must say "beyond X-byte training maximum"
# - test_outputs.py: docstring must accurately describe held-out status
```

### Verification Checklist
- [ ] Count samples in samples.jsonl - does it match task.toml?
- [ ] Check maximum length in samples.jsonl - does it match claims?
- [ ] Verify held-out test tags are NOT in samples.jsonl
- [ ] Ensure documentation accurately describes training vs held-out split
- [ ] Test that oracle still passes with reduced training set

---

## 3. Generic Solution Workflow

### Phase 1: Data Analysis & Categorization
```python
def analyze_training_data(data_path):
    """
    Load and categorize training samples by structure.
    
    Key patterns to identify:
    - Empty/minimal samples → reveal constants (INIT, XOR masks)
    - Single-element samples → constrain internal state (S-boxes, coefficients)
    - Paired samples → reveal relationships (shifts, linear combinations)
    - Multi-element samples → validate full algorithm
    - Edge cases → test boundary conditions
    """
    samples = load_samples(data_path)
    
    categorized = {
        'empty': [],
        'single': [],
        'pairs': [],
        'multi': [],
        'patterns': []
    }
    
    for sample in samples:
        # Categorize by length, pattern, structure...
        if is_empty(sample):
            categorized['empty'].append(sample)
        elif is_single(sample):
            categorized['single'].append(sample)
        # ... etc
    
    print(f"Training data breakdown:")
    for category, items in categorized.items():
        print(f"  {category}: {len(items)} samples")
    
    return categorized
```

### Phase 2: Parameter Space Analysis
```python
def identify_search_space():
    """
    Determine what parameters need to be recovered.
    
    Common parameter types:
    1. Constants: INIT, XOR masks, magic numbers
    2. Linear params: coefficients, shifts, rotations
    3. Non-linear params: S-boxes, tap positions, mixing functions
    4. Structural: polynomial, modulus, base conversion
    """
    
    # Example for MAC algorithm:
    parameters = {
        'polynomial': {
            'candidates': [0x104C11DB7, 0x1EDC6F41, ...],  # Standard GF(2^32) polys
            'source': 'Known CRC/GF polynomials'
        },
        'sbox_mult': {
            'range': range(1, 256, 2),  # Odd numbers for invertibility
            'source': 'Exhaustive (128 values)'
        },
        'sbox_rot': {
            'range': range(8),
            'source': 'Exhaustive (8-bit rotations)'
        },
        'sbox_xor': {
            'range': range(256),
            'source': 'Exhaustive (all XOR masks)'
        },
        'coefficients': {
            'candidates': generate_crypto_constants(),
            'source': 'Mathematical derivation from phi/e/pi/SHA'
        }
    }
    
    # Calculate total search space
    total = 1
    for param, info in parameters.items():
        count = len(info.get('candidates', [])) or len(list(info.get('range', [1])))
        total *= count
        print(f"{param}: {count} candidates ({info['source']})")
    
    print(f"\nTotal search space: {total:,} combinations")
    return parameters
```

### Phase 3: Constraint-Based Recovery
```python
def recover_parameters_incrementally(samples):
    """
    Use constraints from different sample types to narrow parameter space.
    
    Strategy:
    1. Extract constants from empty/minimal samples
    2. Use single-element samples for tight constraints
    3. Use multi-element samples to discriminate between candidates
    4. Validate all parameters against ALL samples
    """
    
    # Step 1: Extract obvious constants
    empty_samples = [s for s in samples if len(s['input']) == 0]
    if empty_samples:
        INIT_CONSTANT = empty_samples[0]['output']
        print(f"[FOUND] INIT constant: 0x{INIT_CONSTANT:08X}")
    
    # Step 2: Constrain via differential analysis
    single_samples = [s for s in samples if len(s['input']) == 1]
    
    # Step 3: Search parameter space with progressive validation
    for param_combo in generate_parameter_combinations():
        # Quick rejection: test on a few single samples first
        if not quick_test(param_combo, single_samples[:4]):
            continue
        
        # CRITICAL: If quick test passes, validate against ALL samples
        if validate_all_samples(param_combo, single_samples):
            # Further validation on multi-element samples
            if validate_multi_samples(param_combo, multi_samples):
                return param_combo
    
    return None
```

### Phase 4: Complete Validation
```python
def validate_solution(params, training_data, test_data=None):
    """
    Validate recovered parameters thoroughly.
    
    Checks:
    1. All training samples match (0 errors required)
    2. Test on held-out data if available
    3. Verify no edge-case failures
    4. Check determinism (same input → same output)
    """
    
    print("\n=== Solution Validation ===")
    
    # Test on ALL training samples (not just a subset!)
    errors = 0
    for sample in training_data:
        computed = compute_with_params(params, sample['input'])
        if computed != sample['expected']:
            errors += 1
            print(f"  ERROR: input={sample['input']}, "
                  f"expected={sample['expected']}, got={computed}")
    
    print(f"Training accuracy: {len(training_data)-errors}/{len(training_data)} "
          f"({100*(1-errors/len(training_data)):.1f}%)")
    
    if errors > 0:
        print("FAILED - Parameters do not match all training samples")
        return False
    
    # Test held-out if available
    if test_data:
        test_errors = 0
        for sample in test_data:
            computed = compute_with_params(params, sample['input'])
            if computed != sample['expected']:
                test_errors += 1
        
        print(f"Test accuracy: {len(test_data)-test_errors}/{len(test_data)}")
        if test_errors > 0:
            return False
    
    print("✓ All validation checks passed")
    return True
```

---

## 3. Common Patterns by Algorithm Type

### Checksum/Hash Functions
**Characteristics:**
- Often based on LFSR, CRC, or simple state machines
- Look for: tap positions, polynomials, initialization vectors, final XOR

**Recovery approach:**
1. Empty samples → determine INIT and FINAL_XOR relationship
2. Single-byte samples → constrain state transitions
3. Use differential pairs to recover shift/rotation amounts
4. Test standard polynomials (CRC-16, CRC-32 variants)

```python
# Standard CRC/LFSR polynomials to test
STANDARD_POLYNOMIALS_16 = [
    0x1021,  # CRC-16-CCITT
    0x8005,  # CRC-16-IBM
    0x8408,  # CRC-16-REVERSED
]

STANDARD_POLYNOMIALS_32 = [
    0x104C11DB7,  # CRC-32 (Ethernet)
    0x1EDC6F41,   # CRC-32C (Castagnoli)
    0x1814141AB,  # CRC-32K (Koopman)
]
```

### MAC/Authentication Tags
**Characteristics:**
- Combines field arithmetic (GF operations) with non-linear mixing
- Look for: field polynomials, S-boxes, round constants, key mixing

**Recovery approach:**
1. Identify field structure (GF(2^n) polynomial)
2. Recover S-box structure (often parametric, not full 256-byte table)
3. Determine state update function (linear recurrence + mixing)
4. **Algebraically derive coefficients** (don't search candidate lists)

```python
# S-box often has parametric structure
def parametric_sbox(byte, mult, rot, xor_const):
    """Many S-boxes are linear transformations, not lookup tables."""
    val = (byte * mult) & 0xFF
    rotated = ((val << rot) | (val >> (8 - rot))) & 0xFF
    return rotated ^ xor_const

# Search S-box parameters (3 values) instead of full 256-byte table
for mult in range(1, 256, 2):      # Odd for invertibility
    for rot in range(8):             # 8-bit rotation
        for xor in range(256):       # XOR mask
            # For each S-box, DERIVE coefficients algebraically
            coeffs = solve_coefficients_algebraically(...)
            if coeffs and validate(coeffs):
                return (mult, rot, xor, coeffs)

# GF(2^32) Algebraic Coefficient Solving
def solve_coefficients_algebraically(poly, sbox_params, init, single_samples):
    """
    For MAC with structure: tag = gf_mult(gf_mult(INIT, A) XOR sbox, B)
    
    Given two single-byte samples:
      tag1 = gf_mult(gf_mult(INIT, A) XOR sbox1, B)
      tag2 = gf_mult(gf_mult(INIT, A) XOR sbox2, B)
    
    Taking XOR difference:
      tag1 XOR tag2 = gf_mult(sbox1 XOR sbox2, B)
    
    Solve for B:
      B = gf_div(tag1 XOR tag2, sbox1 XOR sbox2, poly)
    
    Then solve for A:
      intermediate = gf_div(tag1, B, poly)
      A = gf_div(intermediate XOR sbox1, INIT, poly)
    """
    
    # 1. Implement GF(2^32) field operations
    def gf32_mult(a, b, poly):
        result = 0
        for i in range(32):
            if b & 1:
                result ^= a
            high_bit = a & 0x80000000
            a = (a << 1) & 0xFFFFFFFF
            if high_bit:
                a ^= poly
                a &= 0xFFFFFFFF  # CRITICAL: mask to 32 bits!
            b >>= 1
        return result & 0xFFFFFFFF
    
    def gf32_inverse(a, poly):
        """Extended Euclidean algorithm in GF(2^32)."""
        if a == 0:
            return None
        t, new_t = 0, 1
        r, new_r = poly | (1 << 32), a
        
        while new_r != 0:
            quotient_bit = r.bit_length() - new_r.bit_length()
            if quotient_bit >= 0:
                r ^= new_r << quotient_bit
                t ^= new_t << quotient_bit
            else:
                r, new_r = new_r, r
                t, new_t = new_t, t
        
        if r == 1:
            return t & 0xFFFFFFFF
        return None
    
    def gf32_div(a, b, poly):
        """Field division: a / b = a * b^(-1)."""
        b_inv = gf32_inverse(b, poly)
        if b_inv is None:
            return None
        return gf32_mult(a, b_inv, poly)
    
    # 2. Get two different samples
    bytes_list = sorted(single_samples.keys())
    if len(bytes_list) < 2:
        return None
    
    b1, b2 = bytes_list[0], bytes_list[1]
    tag1, tag2 = single_samples[b1], single_samples[b2]
    
    # 3. Compute S-box outputs
    sbox1 = parametric_sbox(b1, *sbox_params)
    sbox2 = parametric_sbox(b2, *sbox_params)
    
    # 4. Algebraic solving
    sbox_diff = sbox1 ^ sbox2
    if sbox_diff == 0:
        return None  # Can't divide by zero
    
    tag_diff = tag1 ^ tag2
    coeff_b = gf32_div(tag_diff, sbox_diff, poly)
    if coeff_b is None:
        return None
    
    # Back-solve for A
    intermediate = gf32_div(tag1, coeff_b, poly)
    if intermediate is None:
        return None
    
    init_contrib = intermediate ^ sbox1
    coeff_a = gf32_div(init_contrib, init, poly)
    if coeff_a is None:
        return None
    
    # 5. VALIDATE against ALL samples (critical!)
    for byte_val, expected_tag in single_samples.items():
        sbox_val = parametric_sbox(byte_val, *sbox_params)
        state = gf32_mult(init, coeff_a, poly) ^ sbox_val
        computed = gf32_mult(state, coeff_b, poly)
        if computed != expected_tag:
            return None  # Wrong S-box parameters
    
    return (coeff_a, coeff_b)

# RESULT: Coefficients are DERIVED, not guessed from famous constants
# Search space: ~10 polys × 262K S-box combinations
# Each S-box instantly gets algebraically-solved coefficients
# No need to test thousands of coefficient candidates!
```

### Session ID / Token Generators
**Characteristics:**
- Often based on LCG (Linear Congruential Generator) or hash chains
- Look for: secret keys, rotation/mixing functions, encoding schemes

**Recovery approach:**
1. Decode representation (Base62, Base64, hex, etc.)
2. Identify bit-width (64-bit, 128-bit, 256-bit)
3. Split into words and test mixing functions
4. Recover LCG parameters: s[n+1] = (a*s[n] + c) mod m
5. Back-derive secret from seed formula

```python
# LCG parameter recovery from 3 consecutive states
def recover_lcg_params(s0, s1, s2, modulus):
    """
    From recurrence s[n+1] = (a*s[n] + c) mod m:
    s1 = a*s0 + c
    s2 = a*s1 + c
    
    Solve: a = (s2-s1) * modinv(s1-s0) mod m
           c = s1 - a*s0 mod m
    """
    delta1 = (s1 - s0) % modulus
    delta2 = (s2 - s1) % modulus
    
    if delta1 == 0:
        return None
    
    a = (delta2 * modinv(delta1, modulus)) % modulus
    c = (s1 - a * s0) % modulus
    
    return (a, c)
```

---

## 4. Implementation Best Practices

### Generate Output Code Programmatically
```python
def generate_output_code(params):
    """
    Never write output file manually - generate from recovered parameters.
    This ensures consistency between what you found and what you output.
    """
    
    code = f'''def compute_mac(firmware: bytes) -> int:
    """Generated from recovered parameters."""
    IRREDUCIBLE_POLY = 0x{params['poly']:08X}
    SBOX_MULT = 0x{params['mult']:02X}
    SBOX_ROT = {params['rot']}
    SBOX_XOR = 0x{params['xor']:02X}
    COEFF_A = 0x{params['coeff_a']:08X}
    COEFF_B = 0x{params['coeff_b']:08X}
    INIT = 0x{params['init']:08X}
    
    def parametric_sbox(byte):
        val = (byte * SBOX_MULT) & 0xFF
        rotated = ((val << SBOX_ROT) | (val >> (8 - SBOX_ROT))) & 0xFF
        return rotated ^ SBOX_XOR
    
    def gf32_mult(a, b):
        result = 0
        for i in range(32):
            if b & 1:
                result ^= a
            b >>= 1
            a <<= 1
            if a & 0x100000000:
                a ^= IRREDUCIBLE_POLY
        return result
    
    state = INIT
    for byte in firmware:
        sbox_val = parametric_sbox(byte)
        state = gf32_mult(state, COEFF_A) ^ sbox_val
        state = gf32_mult(state, COEFF_B)
    
    return state
'''
    
    return code
```

### Validation Must Use ALL Samples
```python
# ❌ BAD - Only validates subset
bytes_to_test = sorted(single_tags.keys())[:4]  # Only first 4!

# ✅ GOOD - Validates ALL samples
bytes_to_test = list(single_tags.keys())  # ALL single-byte samples

# Validation loop
all_match = True
for byte_val in bytes_to_test:
    computed = compute(byte_val, params)
    expected = single_tags[byte_val]
    if computed != expected:
        all_match = False
        break

if all_match:
    # ALSO test on multi-byte samples before accepting
    for key, expected_tag in two_byte_tags.items():
        computed_tag = compute_multi(key, params)
        if computed_tag != expected_tag:
            all_match = False
            break
```

---

## 5. Common Pitfalls & Solutions

### Pitfall 1: Premature Optimization
**Problem:** Testing only a subset of samples to "speed up" search

**Solution:** Always validate against ALL training samples. Use quick rejection on a few samples, but final validation must be complete.

```python
# Quick rejection (optional for speed)
if not matches_subset(params, samples[:5]):
    continue

# But ALWAYS do full validation before accepting
if matches_all_samples(params, samples):
    return params  # Found it!
```

### Pitfall 2: Unicode/Encoding Issues
**Problem:** Using Unicode characters (✓, ✗) in output that may not be supported

**Solution:** Stick to ASCII
```python
# ❌ BAD
print("✓ Found parameters")

# ✅ GOOD
print("[FOUND] Parameters recovered")
print("✓ All tests passed")  # Or just use ASCII
```

### Pitfall 3: Stale Test Vectors
**Problem:** Test file has hardcoded expected values from wrong implementation

**Solution:** Always regenerate test vectors from ground truth when parameters change

```python
# After recovering correct parameters, regenerate ALL test vectors
def regenerate_test_vectors(ground_truth_impl):
    """Use ground truth implementation to create test vectors."""
    
    test_cases = [
        "42", "7f", "aa",  # Single bytes
        "0303", "0505",    # Two bytes
        # ... more cases
    ]
    
    for test_input in test_cases:
        firmware = bytes.fromhex(test_input)
        expected = ground_truth_impl.compute_mac(firmware)
        print(f'("{test_input}", {expected}),')
```

### Pitfall 4: Using Famous Constants Without Algebraic Solving
**Problem:** Ground truth uses famous constants (CRC-32, golden ratio, 0xDEADBEEF), oracle searches them first

**Solution:** Either use fully random bespoke parameters, OR use standard components with algebraically-solved bespoke parameters

```python
# ❌ BAD - Famous constants enable catalog sweeping
ground_truth = {
    'polynomial': 0x104C11DB7,      # CRC-32 - famous
    'coeff_a': 0x9E3779B9,          # Golden ratio - famous
    'coeff_b': 0x61C88647,          # Inverse golden ratio - famous
    'init': 0xDEADBEEF              # Famous hex pattern
}

oracle_candidates = [
    (0x9E3779B9, 0x61C88647),  # Golden ratio pair FIRST
    # ... other pairs
]
# Result: Model tries famous combo first, succeeds by recall

# ✅ GOOD - Algebraic solving + random parameters
ground_truth = {
    'polynomial': 0x104C11DB7,      # CRC-32 - acceptable (small set of standards)
    'sbox_mult': 0xA3,              # RANDOM odd value
    'sbox_rot': 7,                  # RANDOM 0-7
    'sbox_xor': 0x14,               # RANDOM 0-255
    'coeff_a': 0x43D6E10B,          # RANDOM odd - NO PRIOR ART
    'coeff_b': 0xD1B553F7,          # RANDOM odd - NO PRIOR ART
    'init': 0xF1D1A748              # RANDOM
}

# Oracle searches S-box exhaustively, then DERIVES coefficients algebraically
for poly in [CRC-32, CRC-32C, ...]:  # ~10 standard polynomials
    for sbox_params in exhaustive_sbox_search():  # 262K combinations
        # ALGEBRAICALLY DERIVE coefficients (not search!)
        coeffs = solve_coefficients_algebraically(poly, sbox_params, samples)
        if coeffs and validate_all(poly, sbox_params, coeffs, samples):
            return (poly, sbox_params, coeffs)

# Result: Model can't guess random S-box or coefficients - must do real cryptanalysis
```

### Pitfall 5: Held-Out Tests That Aren't Held-Out
**Problem:** Test file claims samples are "NOT in training" but they actually are

**Solution:** Remove held-out samples from training data, update documentation

```python
# After generating all samples, explicitly remove held-out ones
all_samples = generate_all_samples(params)

# Separate training vs held-out
training = [s for s in all_samples if keep_in_training(s)]
held_out = [s for s in all_samples if not keep_in_training(s)]

# Save training ONLY
with open('environment/data/samples.jsonl', 'w') as f:
    for sample in training:
        f.write(json.dumps(sample) + '\n')

# Use held-out for test generation
for sample in held_out:
    print(f'("{sample["firmware_hex"]}", {sample["tag"]}),')
```

---

## 6. Testing & Verification

### Oracle Solution Requirements
Your oracle solution must:
1. ✅ Genuinely recover parameters (no hardcoding)
2. ✅ Pass ALL tests (reward = 1.0)
3. ✅ Generate correct output file
4. ✅ Complete within time limits (typically 30-60 seconds)
5. ✅ Print clear progress/debug info

### Test File Requirements  
Your test_outputs.py must:
1. ✅ Use ONLY genuinely held-out data (verify NOT in samples.jsonl)
2. ✅ Have correct expected values (regenerated from ground truth)
3. ✅ Test edge cases (empty, single, long, patterns)
4. ✅ Use exact equality (no tolerance for discrete outputs)
5. ✅ **Docstrings accurately describe held-out status** - don't claim "NOT in training" if they are!
6. ✅ **Include extrapolation tests** - byte values or lengths beyond training range

### Held-Out Data Verification
```bash
# Check held-out test tags are NOT in training data
cd environment/data
grep "3827718941" samples.jsonl  # Should return nothing for held-out tag
grep "2762911996" samples.jsonl  # Should return nothing for held-out tag

# Check training data maximum length
python -c "
import json
with open('samples.jsonl') as f:
    samples = [json.loads(line) for line in f]
max_len = max(len(s['firmware_hex'])//2 for s in samples)
print(f'Training maximum: {max_len} bytes')
"
# Should match claims in task.toml (e.g., "128 bytes")

# Verify held-out tests exceed training maximum
# If task.toml claims 150/200/250/256-byte tests are "beyond training maximum",
# then training maximum must be < 150 (e.g., 128)
```

### Running Validation
```bash
# Local test
cd task
python solution/solve.py

# Oracle test (full Docker environment)
harbor run -p . -a oracle

# Check results
harbor view jobs
```

---

## 7. Task.toml Consistency Checklist

Before finalizing, verify task.toml matches implementation:

- [ ] Sample counts match (e.g., "65 training samples" - count lines in samples.jsonl)
- [ ] Parameter counts match (e.g., "6 parameters: poly + 3 S-box + 2 coefficients")
- [ ] Search space math is correct (10 polys × 8 rots × 128 mults × 256 xors = 2.6M)
- [ ] Difficulty explanation matches actual solution approach (algebraic solving vs search)
- [ ] **verification_explanation accurately describes held-out data**:
  - [ ] States correct number of held-out test vectors
  - [ ] Correctly identifies which samples are NOT in training (byte values, lengths)
  - [ ] States correct training maximum (e.g., "128 bytes")
  - [ ] Claims about "beyond training maximum" are factually accurate
- [ ] **No famous constants used UNLESS**:
  - [ ] They're from a small standard set (~10 items), AND
  - [ ] Other parameters are genuinely bespoke (random, no prior art), AND
  - [ ] Bespoke parameters are algebraically derived (not searched)
- [ ] Timeouts are appropriate (agent: 1800s, verifier: 180s)
- [ ] Artifacts list is correct (["/app/firmware_mac.py"])
- [ ] Test weights sum to 100% and match test file

---

## 8. Quick Reference: Parameter Recovery Checklist

For any new reverse engineering task:

1. **Load & categorize data**
   - [ ] Group by length/structure
   - [ ] Identify empty/minimal samples
   - [ ] Find edge cases

2. **Identify parameter space**
   - [ ] List all parameters to recover
   - [ ] Determine search strategy for each
   - [ ] Calculate total search space
   - [ ] Ensure NO hardcoded answers in candidate lists

3. **Extract constants**
   - [ ] Use empty samples for INIT
   - [ ] Use differential pairs for shifts/rotations
   - [ ] Identify field/modulus from overflow behavior

4. **Search with validation**
   - [ ] Quick rejection on small subset
   - [ ] Full validation on ALL samples
   - [ ] Test on multiple sample types (single, multi, patterns)

5. **Generate output**
   - [ ] Programmatically create output file
   - [ ] Include all recovered parameters
   - [ ] Test generated code independently

6. **Verify solution**
   - [ ] 0 errors on training data
   - [ ] Passes all held-out tests
   - [ ] Completes within time limits
   - [ ] No Unicode/encoding issues

---

## Example: Full Recovery Pipeline

```python
#!/usr/bin/env python3
"""Generic reverse engineering solution template."""

import json
import sys

def main():
    print("=== Reverse Engineering Solution ===\n")
    
    # Step 1: Load and analyze
    print("[Step 1] Loading training data...")
    samples = load_samples('/app/samples.jsonl')
    categorized = categorize_samples(samples)
    
    # Step 2: Extract constants
    print("[Step 2] Extracting constants...")
    constants = extract_constants(categorized)
    
    # Step 3: Define search space
    print("[Step 3] Defining parameter search space...")
    param_space = define_search_space()
    
    # Step 4: Search for parameters
    print("[Step 4] Searching for parameters...")
    recovered_params = search_parameters(
        param_space, 
        categorized, 
        constants
    )
    
    if recovered_params is None:
        print("ERROR: No valid parameters found")
        sys.exit(1)
    
    # Step 5: Validate
    print("[Step 5] Validating solution...")
    if not validate_all(recovered_params, samples):
        print("ERROR: Validation failed")
        sys.exit(1)
    
    # Step 6: Generate output
    print("[Step 6] Generating output file...")
    output_code = generate_code(recovered_params)
    with open('/app/output.py', 'w') as f:
        f.write(output_code)
    
    print("\n✓ Solution complete")
    print(f"Parameters: {recovered_params}")

if __name__ == '__main__':
    main()
```

---

## Summary

**Key Principles:**
1. **Never hardcode the answer** - use exhaustive ranges or algebraic derivation
2. **Avoid famous constants** - use random bespoke parameters or algebraically-solved values
3. **Held-out data must be TRULY held-out** - verify NOT in training, update documentation
4. **Validate against ALL samples** - don't accept partial matches
5. **Generate output programmatically** - ensure consistency
6. **Test thoroughly** - genuinely held-out data, edge cases, determinism
7. **Document accurately** - verification_explanation must match reality

**Success Criteria:**
- Oracle reward = 1.0 (all tests pass)
- No hardcoded answers in parameter candidates
- No famous constants enabling catalog sweeping (or use algebraic solving)
- All held-out test vectors genuinely NOT in training data
- Documentation (task.toml, test docstrings) accurately describes held-out status
- Completes in reasonable time (<2 minutes)
- Clean, readable code with clear logic
- Consistent with task.toml documentation

---

## 9. Key Lessons From Feedback

### Lesson 1: Famous Constants Enable Catalog Sweeping
**Problem:** Task used CRC-32 polynomial + golden ratio coefficients (0x9E3779B9, 0x61C88647) + 0xDEADBEEF init. Oracle searched these famous constants first. Stronger models could succeed by trying "one lucky CRC-poly-plus-golden-ratio hypothesis" instead of genuine cryptanalysis.

**Solution:** Generate **bespoke parameters with NO public prior art**:
```python
import secrets

# RANDOM bespoke parameters (no connection to famous constants)
params = {
    'polynomial': 0x104C11DB7,       # CRC-32 acceptable (small standard set)
    'sbox_mult': secrets.choice([m for m in range(1, 256, 2)]),  # RANDOM
    'sbox_rot': secrets.randbelow(8),                             # RANDOM
    'sbox_xor': secrets.randbelow(256),                           # RANDOM
    'coeff_a': secrets.randbelow(2**32) | 1,                      # RANDOM (no golden ratio!)
    'coeff_b': secrets.randbelow(2**32) | 1,                      # RANDOM
    'init': secrets.randbelow(2**32)                              # RANDOM (no 0xDEADBEEF!)
}
```

**Critical:** Oracle must **algebraically derive** coefficients, not search candidate lists containing famous constants.

### Lesson 2: Algebraic Solving > Candidate Lists
**Problem:** Original oracle tested 50 coefficient candidates including golden ratio pairs. Coefficients (0x8E6F0321, 0x0353CE3F) weren't in the random seed=42 generation, causing oracle failure.

**Solution:** Implement **GF(2^32) algebraic coefficient solving**:
- Derive B from: `B = (tag1 XOR tag2) / (sbox1 XOR sbox2)`
- Back-solve for A using field division
- Replaces searching thousands of candidates with instant algebraic derivation
- Works for ANY random coefficients (no hardcoding needed)

**Result:** Search space reduced from 10 polys × 262K S-box × 50 coeffs = 131M to just 10 polys × 262K S-box = 2.6M combinations, runtime ~55 seconds.

### Lesson 3: Held-Out Data Must Be Genuinely Held-Out
**Problem:** Four test vectors (150/200/250/256-byte samples, tags 2762911996/1296584358/1480829296/3444057713) were claimed "NOT in training data" but were actually IN samples.jsonl lines 64-67.

**Solution:**
1. Remove 150/200/250/256-byte samples from samples.jsonl
2. Training data now: 65 samples, maximum 128 bytes
3. Test vectors now: 6 genuinely held-out (0x20, 0x42 single bytes + 4 long sequences)
4. Update verification_explanation to accurately state "beyond 128-byte training maximum"

**Impact:** Tests now force genuine extrapolation beyond training range, preventing lookup-table memorization.

### Lesson 4: Verification Explanation Must Match Reality
**Problem:** task.toml claimed "25 held-out vectors" and "NOT in training data" but 4 of 6 vectors were actually in training.

**Solution:**
- Count lines in samples.jsonl (verify 65, not 69)
- Grep for held-out tags to confirm absence
- Check maximum byte length in training (verify 128, not 256)
- Rewrite verification_explanation with accurate counts and claims

### Lesson 5: Hardening Requires Eliminating ALL Shortcuts
**Task must fail models on reasoning, not lucky guesses:**

1. ❌ **Recall escape** - Famous constants (CRC-32 + golden ratio) allow catalog sweeping
   - ✅ **Fix:** Random bespoke coefficients with algebraic solving

2. ❌ **Memorization escape** - "Held-out" tests in training data
   - ✅ **Fix:** Remove from training, verify genuinely held-out

3. ❌ **Hardcoding escape** - Oracle contains ground truth in candidate lists
   - ✅ **Fix:** Algebraic derivation, exhaustive ranges only

**Final validation:**
- [ ] Oracle passes with reward 1.0
- [ ] Oracle contains NO ground truth values in candidate lists (except exhaustive/standard sets)
- [ ] All held-out test tags verified NOT in samples.jsonl
- [ ] task.toml verification_explanation factually accurate
- [ ] Instruction.md mentions "bespoke/custom construction, no published prior art"

---

## 10. Quick Pre-Submission Checklist

Before submitting a reverse engineering task:

**Parameters & Constants:**
- [ ] No famous constants used (or if used, other components are bespoke + algebraically solved)
- [ ] Ground truth parameters generated with `secrets` module (truly random)
- [ ] Oracle uses exhaustive search OR algebraic derivation (no candidate lists containing the answer)
- [ ] If using standard components (CRC-32), limited to small set (~10 items) and clearly necessary

**Training Data:**
- [ ] Count samples: `wc -l environment/data/samples.jsonl` matches task.toml
- [ ] Check max length: verify matches claims about "training maximum"
- [ ] Held-out tests verified NOT in training: `grep [held_out_tag] samples.jsonl` returns nothing

**Test File:**
- [ ] All test vectors genuinely held-out (not in samples.jsonl)
- [ ] Tests include extrapolation beyond training range (byte values, lengths)
- [ ] Docstrings accurately describe held-out status (no false claims)

**Documentation:**
- [ ] task.toml verification_explanation factually accurate
- [ ] Sample counts, parameter counts, search space math all correct
- [ ] instruction.md mentions bespoke/custom construction if applicable

**Oracle Solution:**
- [ ] Passes with reward 1.0: `harbor run -p . -a oracle`
- [ ] Runtime reasonable (<2 minutes)
- [ ] No hardcoded answers in parameter candidates
- [ ] Uses algebraic solving where possible (not guessing from famous constants)

**Final Check:**
- [ ] Run `harbor run -p . -a oracle` one more time to confirm
- [ ] Review all feedback points addressed
- [ ] Verify no escape hatches remain (recall, memorization, hardcoding)
