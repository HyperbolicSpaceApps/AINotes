import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmbeddingService {
  final String apiKey;
  static const _url = 'https://api.jina.ai/v1/embeddings';
  static const _model = 'jina-embeddings-v3';

  EmbeddingService({required this.apiKey});

  Future<List<double>> embedDocument(String text) =>
      _embed(text, 'retrieval.passage');

  Future<List<double>> embedQuery(String text) =>
      _embed(text, 'retrieval.query');

  Future<List<double>> _embed(String text, String task) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'task': task,          
        'dimensions': 512,     
        'normalized': false,    
        'input': [
          {'text': text}       
        ],
      }),
    );


    debugPrint('Jina status: ${response.statusCode}');
    debugPrint('Jina body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Embedding failed ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return List<double>.from(data['data'][0]['embedding']);
  }
}