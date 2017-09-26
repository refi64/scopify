import 'package:test/test.dart';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:uuid/uuid.dart';

import 'package:scopify/scopify.dart';


Element parseHtml(String text) => html.parse(text).querySelector('body *');

String cssString(StyleSheet style) {
  var printer = new CssPrinter();
  style.visit(printer);
  return printer.toString();
}


String roundTripHtml(String uuid, String htmlText) {
  var node = parseHtml(htmlText);
  scopify(html: [node], css: [], uuid: uuid);
  return node.outerHtml;
}


String roundTripCss(String uuid, String cssText) {
  var style = css.parse(cssText);
  scopify(html: [], css: [style], uuid: uuid);
  return cssString(style);
}


void testHtml(String uuid, String orig, String next) {
  expect(roundTripHtml(uuid, orig), equals(parseHtml(next).outerHtml));
}


void testCss(String uuid, String orig, String next) {
  expect(roundTripCss(uuid, orig), equals(cssString(css.parse(next))));
}


String genId() => new Uuid().v4();
String genAttr(String uuid) => 'scoped-data-$uuid';


void main() {
  test('adds the proper UUIDs', () {
    var uuid = genId();
    var attr = genAttr(uuid);

    testHtml(uuid, '<p test>abc<a>x</a></p>',
                   '<p test $attr>abc<a $attr>x</a></p>');
  });

  test('converts the CSS to use the proper UUIDs', () {
    var uuid = genId();
    var attr = genAttr(uuid);

    testCss(uuid, 'a, .b:not(#c) > d',
                  'a[$attr], .b:not(#c)[$attr] > d, [$attr] a, [$attr] .b:not(#c) > d');
  });
}
