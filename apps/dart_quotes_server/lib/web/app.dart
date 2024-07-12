import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/home_page.dart';
import 'pages/quote_page.dart';

class App extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div(classes: 'main', [
      Router(
        routes: [
          Route(path: '/', builder: (context, state) => HomePage()),
          Route(
              path: '/quote/:quoteId',
              builder: (context, state) => QuotePage(id: int.tryParse(state.params['quoteId']!) ?? 0)),
        ],
      ),
    ]);
    yield a(classes: "github-badge", href: "https://github.com/schultek/jaspr", attributes: {
      'aria-label': "Find the source on Github"
    }, [
      img(src: '/images/github-badge.svg', alt: "Github Badge"),
    ]);
  }

  static get styles => [
        css('.main').box(
          minHeight: 100.vh,
          maxWidth: 500.px,
          margin: EdgeInsets.all(Unit.auto),
          padding: EdgeInsets.symmetric(horizontal: 2.em),
        ),
        css('.github-badge').box(position: Position.absolute(top: 0.px, right: 0.px))
      ];
}
