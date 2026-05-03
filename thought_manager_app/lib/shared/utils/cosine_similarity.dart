import 'dart:math';

// * Computes cosine similarity between two vectors
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError('Vectors must have the same length');
  }

  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += pow(a[i], 2);
    normB += pow(b[i], 2);
  }

  if (normA == 0 || normB == 0) {
    return 0.0; // avoid division by zero
  }

  return dotProduct / (sqrt(normA) * sqrt(normB));
}