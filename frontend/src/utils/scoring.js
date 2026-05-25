const resultSign = (homeScore, awayScore) => {
  if (homeScore > awayScore) return 'home';
  if (homeScore < awayScore) return 'away';
  return 'draw';
};

export const calculatePredictionPoints = (prediction, match) => {
  if (
    !prediction ||
    match.homeScore === null ||
    match.awayScore === null ||
    match.homeScore === undefined ||
    match.awayScore === undefined
  ) {
    return 0;
  }

  const predictedHome = Number(prediction.homeScore);
  const predictedAway = Number(prediction.awayScore);

  if (predictedHome === match.homeScore && predictedAway === match.awayScore) {
    return 5;
  }

  return resultSign(predictedHome, predictedAway) === resultSign(match.homeScore, match.awayScore)
    ? 3
    : 0;
};
