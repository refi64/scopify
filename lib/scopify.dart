import 'package:csslib/visitor.dart';
import 'package:csslib/parser.dart';
import 'package:html/dom.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:uuid/uuid.dart';


final String _BASE_ATTR = 'scopify-data';


class _ScopifyVisitor extends Visitor {
  String scopedAttr;
  bool bleeds;

  _ScopifyVisitor(this.scopedAttr, this.bleeds);

  AttributeSelector _makeAttr(String attr, SourceSpan span) =>
    new AttributeSelector(
      new Identifier(attr, span),
      TokenKind.NO_MATCH,
      null,
      span);

  AttributeSelector _attr(SourceSpan span) => _makeAttr(scopedAttr, span);

  void visitSelectorGroup(SelectorGroup node) {
    var selectors = new List.from(node.selectors);

    for (var selector in selectors) {
      if (bleeds) {
        var prefix = new SimpleSelectorSequence(_attr(selector.span), selector.span);
        var newSelectors = [prefix]..addAll(selector.simpleSelectorSequences);
        newSelectors[1] = newSelectors[1].clone();
        newSelectors[1].combinator = TokenKind.COMBINATOR_DESCENDANT;

        var neg = new NegationSelector(_makeAttr(_BASE_ATTR, selector.span),
                                       selector.span);
        newSelectors.add(new SimpleSelectorSequence(neg, selector.span));

        node.selectors.add(new Selector(newSelectors, selector.span));
      }

      selector.visit(this);
    }
  }

  void visitSelector(Selector node) {
    var sequences = node.simpleSelectorSequences;
    var i = 0;

    for (; i<sequences.length; i++) {
      if (!sequences[i].isCombinatorNone) {
        assert(i != 0);
        break;
      }
    }

    node.simpleSelectorSequences.insert(i, new SimpleSelectorSequence(_attr(node.span),
                                                                      node.span));
  }
}


void _scopifyHtml(Node node, String scopedAttr) {
  node.attributes[_BASE_ATTR] = node.attributes[scopedAttr] = '';
  for (var child in node.children) {
    _scopifyHtml(child, scopedAttr);
  }
}

/// Processes the given HTML nodes and CSS style sheets, modifying them in-place to implement
/// scoped styling.
void scopify({@required List<Node> html, @required List<StyleSheet> css,
              String uuid = null, bool bleeds = false}) {
  var scopedAttr = 'scopify-data-${uuid ?? new Uuid().v4()}';

  for (var node in html) {
    _scopifyHtml(node, scopedAttr);
  }

  for (var style in css) {
    style.visit(new _ScopifyVisitor(scopedAttr, bleeds));
  }
}
