const articleCategoryLabels = {
  'before': 'قبل ما تبلّش',
  'contract': 'العقد والدفع',
  'during': 'خلال الشغل',
  'handover': 'الاستلام',
  'care': 'بعد ما تسكن',
};

/// A tip for customers, written in the dashboard.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
    required this.checklist,
    this.summary,
    this.service,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String category;

  /// Plain text: "## " starts a heading, "- " a bullet, a blank line a paragraph.
  final String body;
  final List<String> checklist;
  final String? summary;
  final String? service;
  final String? coverUrl;

  String get categoryLabel => articleCategoryLabels[category] ?? category;
}

/// One block of an article body.
sealed class ArticleBlock {
  const ArticleBlock();
}

class HeadingBlock extends ArticleBlock {
  const HeadingBlock(this.text);
  final String text;
}

class ParagraphBlock extends ArticleBlock {
  const ParagraphBlock(this.text);
  final String text;
}

class BulletsBlock extends ArticleBlock {
  const BulletsBlock(this.items);
  final List<String> items;
}

/// Splits the plain-text body into headings, paragraphs and bullet lists.
List<ArticleBlock> parseArticle(String body) {
  final blocks = <ArticleBlock>[];
  final paragraph = <String>[];
  final bullets = <String>[];

  void flush() {
    if (paragraph.isNotEmpty) blocks.add(ParagraphBlock(paragraph.join(' ')));
    if (bullets.isNotEmpty) blocks.add(BulletsBlock([...bullets]));
    paragraph.clear();
    bullets.clear();
  }

  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add(HeadingBlock(line.substring(3).trim()));
    } else if (line.startsWith('- ')) {
      if (paragraph.isNotEmpty) {
        blocks.add(ParagraphBlock(paragraph.join(' ')));
        paragraph.clear();
      }
      bullets.add(line.substring(2).trim());
    } else {
      if (bullets.isNotEmpty) {
        blocks.add(BulletsBlock([...bullets]));
        bullets.clear();
      }
      paragraph.add(line);
    }
  }
  flush();
  return blocks;
}
