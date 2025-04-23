class Document {
  final String id;
  final String issueDate;
  final String receiveDate;
  final String from;
  final String to;
  final String subject;
  final String signature;

  Document({
    required this.id,
    required this.issueDate,
    required this.receiveDate,
    required this.from,
    required this.to,
    required this.subject,
    required this.signature,
  });
}