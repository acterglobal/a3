import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

void onBoardingDialog({
  required BuildContext context,
  required String btnText,
  required String btn2Text,
  required void Function() onPressed1,
  required void Function() onPressed2,
  required bool canDismissable,
}) {
  showModalBottomSheet(
    useRootNavigator: true,
    enableDrag: false,
    isScrollControlled: true,
    context: (context),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: <Color>[
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.neutral,
              ],
            ),
          ),
          child: ListView(
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Center(
                child: SvgPicture.asset(
                  'assets/icon/acter.svg',
                  width: 100,
                  height: 100,
                ),
              ),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Welcome to ',
                    style: Theme.of(context).textTheme.headlineLarge,
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Acter!',
                        style:
                            Theme.of(context).textTheme.headlineLarge!.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                margin: const EdgeInsets.only(left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Acter is an all-in-one organizing tool for grassroots and non-profits.‍',
                      style: Theme.of(context).textTheme.bodyMedium,
                      softWrap: true,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'In Acter, you can:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '\t\t\u2022 gather your organization in spaces',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\t\t\u2022 streamline your communication',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\t\t\u2022 enhance your cooperation',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Let\'s get started!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    onPressed1();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.neutral6,
                    foregroundColor: Theme.of(context).colorScheme.neutral,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    fixedSize: const Size(311, 61),
                    shape: RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        btnText,
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right_outlined)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    onPressed2();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.neutral6,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    fixedSize: const Size(311, 61),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.neutral6,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(btn2Text),
                ),
              ),
              const SizedBox(height: 36),
              canDismissable
                  ? GestureDetector(
                      onTap: () => context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text('Skip'),
                            SizedBox(width: 5),
                            Icon(Icons.chevron_right)
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      );
    },
  );
}
