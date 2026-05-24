const DAY_MAP: Record<string, number> = {
  mon: 1,
  tue: 2,
  wed: 3,
  thu: 4,
  fri: 5,
  sat: 6,
  sun: 0,
};

/**
 * Generate candidate dates from a schedule rule.
 * Starts from day1, picks dates matching the specified days,
 * until we have `count` dates.
 */
export function generateCandidateDates(
  day1: string,
  days: string[],
  count: number
): string[] {
  const results: string[] = [];
  const targetDays = new Set(days.map((d) => DAY_MAP[d]));
  const current = new Date(day1 + "T00:00:00Z");

  // Safety: max 365 days lookahead
  const maxIterations = 365;
  let iterations = 0;

  while (results.length < count && iterations < maxIterations) {
    if (targetDays.has(current.getUTCDay())) {
      results.push(current.toISOString().split("T")[0]);
    }
    current.setUTCDate(current.getUTCDate() + 1);
    iterations++;
  }

  return results;
}

/**
 * Get day abbreviation from a date string.
 */
export function getDayAbbr(dateStr: string): string {
  const dayNum = new Date(dateStr + "T00:00:00Z").getUTCDay();
  const reverse: Record<number, string> = {
    0: "sun",
    1: "mon",
    2: "tue",
    3: "wed",
    4: "thu",
    5: "fri",
    6: "sat",
  };
  return reverse[dayNum];
}
