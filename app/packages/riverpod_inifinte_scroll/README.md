# Riverpod Infinite Scroll

Hi! This package is a plugin for [infinite_scroll_pagination](https://pub.dev/packages/infinite_scroll_pagination) that is designed to work with [Riverpod](https://riverpod.dev).

| [Easy](#example---simple-version)                                                               | [Custom](#a-more-custom-example)                                                                    |
| ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| ![easy](https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/readme_assets/easy.gif) | ![custom](https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/readme_assets/custom.gif) |

# Getting started:

```bash
flutter pub get riverpod_infinite_scroll
flutter pub get infinite_scroll_pagination

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
```

# How it works

This package exports a widget, `RiverPagedBuilder` which builds your infinite, scrollable list.

`RiverPagedBuilder` expects a Riverpod [StateNotifierProvider](https://riverpod.dev/docs/providers/state_notifier_provider)

This `StateNotifierProvider` must implement two methods to ensure everything works correctly, it must have a `load method`, and a `nextPageKeyBuilder` method, these will be explained below.

`riverpod_infinite_scroll` ensures our `StateNotifier` will respect these constraints with the choice of two classes:

You can either use the simple:

- `PagedNotifier` - You can create a class that extends `PagedNotifier` a notifier that has all the properties that `riverpod_infinite_scroll` needs and is intended for simple states only containing a list of `records`

- Or if you need more flexbility to handle a more complex state object you can use a `StateNotifier` that uses `PagedState` (or a state that extends PagedState) - in such case a mixin that ensures your `StateNotifier` will implement the `load` method with the correct types is provided with `PagedNotifierMixin`

## Example - Simple version

Let's see an example now! We have an API that returns a list of `Post` objects, this API is paginated and we need to show a feed displaying those Posts.

The widget we will use for displaying such a feed is `RiverPagedBuilder!`. Refer to source code: [easy_example.dart](https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/example/lib/easy/easy_example.dart)

```dart
    class EasyExample extends StatelessWidget {

      const EasyExample({Key? key} :super(key: key);

      @override
      Widget build(BuildContext  context){
        return Scaffold(
          appBar: AppBar(),
          body: RiverPagedBuilder<int, Post>(
          firstPageKey: 0,
          provider: easyExampleProvider,
          itemBuilder: (context, item, index) => ListTile(
            leading: Image.network(item.image),
            title: Text(item.title),
          ),
          pagedBuilder: (controller, builder) =>
              PagedListView(pagingController: controller, builderDelegate: builder),
          ),
        );
      }
    }
```

As we can see `RiverPagedBuilder` is small and easy to implement with the following properties:

1.  `firstPageKey` - the first page we sent to our paginated API
2.  `provider` - The `StateNotifierProvider` that holds the logic and the list of Posts
3.  `itemBuilder` - a function that builds a single Post
4.  `pagedBuilder` - The type of list we want to render. This can be any of the `infinite_scroll_pagination` widgets, and this package already gives us the `PaginationController` and the `BuilderDelegate`

Let's see how our `StateNotifier` works.

Here is our model `Post`:

```dart
    class  Post {
      final  int  id;
      final  String  title;
      final  String  image;
      const  Post({ required  this.id, required  this.title, required  this.image });
    }
```

And the `StateNotifier`. Source code: [easy_example_provider.dart](https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/example/lib/easy/easy_example_provider.dart)

```dart
    class EasyExampleNotifier extends PagedNotifier<int, Post> {

      EasyExampleNotifier():
      super(
        //load is a required method of PagedNotifier
        load: (page, limit) => Future.delayed(const  Duration(seconds: 2), () {
          // This simulates a network call to an api that returns paginated posts
          return [
          const  Post(id: 1, title: "My first work", image: "https://www.mywebsite.com/image1"),
          const  Post(id: 2, title: "My second work", image: "https://www.mywebsite.com/image2"),
          const  Post(id: 3, title: "My third work", image: "https://www.mywebsite.com/image3"),
          ];
        }),

        //nextPageKeyBuilder is a required method of PagedNotifier
        nextPageKeyBuilder: NextPageKeyBuilderDefault.mysqlPagination,
      );

      // Example of custom methods you are free to implement in StateNotifier
      void  add(Post  post) {
        state = state.copyWith(records: [ ...(state.records ?? []), post ]);
      }
      void  delete(Post  post) {
        state = state.copyWith(records: [ ...(state.records ?? []) ]..remove(post));
      }
    }

    //create a global provider as you would normally in riverpod:
    final  easyExampleProvider = StateNotifierProvider<EasyExampleNotifier, PagedState<int, Post>>((_) => EasyExampleNotifier());
```

We can extend `PagedNotifier` which is a child of `StateNotifier` and everything will be done for us.

`PagedNotifier` only asks for a load function, and a `nextPageKeyBuilder` function that returns the next page. and that's it!

In the example above we used `NextPageKeyBuilderDefault.mysqlPagination` , a default function to reduce boilerplate.

```dart
 NextPageKeyBuilder<int, dynamic> mysqlPagination =
    (List<dynamic>? lastItems, int  page, int  limit) {
	    return (lastItems == null || lastItems.length < limit) ? null : (page + 1);
    };
```

Also notice the `records` member of the internal `state` object of `PagedNotifier` is accessible and modifiable in the standard Riverpod way through this custom function `add`

```dart
void  add(Post  post) {
  state = state.copyWith(records: [ ...(state.records ?? []), post ]);
}
```

## A more custom example

If you need to keep track of a more complex state than a simple list of `records` **Riverpod Infinite Scroll** also provides a more customizable approach.
Let's suppose we need to fetch from a paginated API that return a list of users. Source code: (custom_example.dart)[https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/example/lib/custom/custom_example.dart]

```dart
    class CustomExample extends StatelessWidget {
      const CustomExample({Key? key}) : super(key: key);

      @override
      Widget  build(BuildContext  context) {
        return  Scaffold(
          appBar: AppBar(),
          body: RiverPagedBuilder<String, User>(
            firstPageKey: 'FirstPage',
            provider: customExampleProvider,
            itemBuilder: (context, item, index) => ListTile(
              leading: Image.network(item.profilePicture),
              title: Text(item.name),
            ),
            pagedBuilder: (controller, builder) => PagedGridView(
              pagingController: controller,
              builderDelegate: builder,
              gridDelegate: const  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
            ),
          ),
        );
      }
    }
```

> We have used a `PagedGridView` here instead of a `PagedListView` only to make things more fun. This package works with any of the `infinite_scroll_pagination` widgets.

Now let's have a look of how we can create a more custom `StateNotifier`, first a simple class to represent a User:

```dart
    class  User {
      final  String  id;
      final  String  name;
      final  String  profilePicture;
      const  User({ required  this.id, required  this.name, required  this.profilePicture });
    }
```

And we have the `StateNotifier` that manages those users. Source code: (custom_example_provider.dart)[https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/example/lib/custom/custom_example_provider.dart]

```dart
class CustomExampleNotifier extends StateNotifier<CustomExampleState>
    with PagedNotifierMixin<String, User, CustomExampleState> {
  CustomExampleNotifier() : super(const CustomExampleState());

  @override
  Future<List<User>?> load(String page, int limit) async {
    try {
      //as build can be called many times, ensure
      //we only hit our page API once per page
      if (state.previousPageKeys.contains(page)) {
        await Future.delayed(const Duration(seconds: 0), () {
          state = state.copyWith();
        });
        return state.records;
      }
      var users = await Future.delayed(const Duration(seconds: 3), () {
        // This simulates a network call to an api that returns paginated users
        return [
          const User(
              id: "abcdef",
              name: "John",
              profilePicture: "https://www.mywebsite.com/images/1"),
          const User(
              id: "asdfgh",
              name: "Mary",
              profilePicture: "https://www.mywebsite.com/images/2"),
          const User(
              id: "qwerty",
              name: "Robert",
              profilePicture: "https://www.mywebsite.com/images/3")
        ];
      });

      // we then update state accordingly
      state = state.copyWith(records: [
        ...(state.records ?? []),
        ...users
      ], nextPageKey: users.length < limit ? null : users[users.length - 1].id,
         previousPageKeys: {...state.previousPageKeys, page}.toList());
    } catch (e) {
      // in case of error we should notifiy the listeners
      state = state.copyWith(error: e.toString());
    }
  }

  // Super simple example of custom methods of the StateNotifier
  void add(User user) {
    state = state.copyWith(records: [...(state.records ?? []), user]);
  }

  void delete(User user) {
    state = state.copyWith(records: [...(state.records ?? [])]..remove(user));
  }
}

final customExampleProvider =
    StateNotifierProvider<CustomExampleNotifier, CustomExampleState>(
        (_) => CustomExampleNotifier());

```

We didn't use `PagedNotifier`, instead we used a normal Riverpod `StateNotifier` with the `PagedNotifierMixin` which ensures the notifier has a correctly typed `load` method.

Let's take a closer look at :

```dart
 Future<List<User>?> load(String page, int limit) async {
```

Where does this `String page` get set? Well some of you may have noticed this `firstPageKey` whatever string is in there will be passed to the `page` argument of `load`:

```dart
 body: RiverPagedBuilder<String, User>(
            firstPageKey: 'FirstPage',
```

It is also important to note that you are responsible for maintaining the `records` list:

```dart
state = state.copyWith(records: [
        ...(state.records ?? []),
        ...users
      ], nextPageKey: users.length < limit ? null : users[users.length - 1].id,
         previousPageKeys: {...state.previousPageKeys, page}.toList());
```

Also, in this example, we have used a custom state that extends `PagedState`, because we need another custom parameter `filterByCity`:

```dart
    class CustomExampleState extends PagedState<String, User> {
   	// We can extends [PagedState] to add custom parameters to our state
   	final  bool  filterByCity;

   	const  CustomExampleState({
          this.filterByCity = false,
          List<User>? records,
          String? error,
          String? nextPageKey,
          List<String>? previousPageKeys }):
          super(records: records, error: error, nextPageKey: nextPageKey);

   	    // We can customize our .copyWith for example
   	    @override
   	    CustomExampleState  copyWith({
                bool? filterByCity,
                List<User>? records,
                dynamic  error,
                dynamic  nextPageKey,
                List<String>? previousPageKeys
   	        }){
                    final  sup = super.copyWith(
                      records: records,
                      error: error,
                      nextPageKey: nextPageKey,
                      previousPageKeys: sup.previousPageKeys);
                    );

   		    return  CustomExampleState(
                      filterByCity: filterByCity ?? this.filterByCity,
                      records: sup.records,
                      error: sup.error,
                      nextPageKey: sup.nextPageKey,
                      previousPageKeys: sup.previousPageKeys);
   		    );
   	    }
    }
```

Your custom arg for `firstPageKey` does not have to be a `String` it can be any type as specified when you declared your Notifier:

```dart
class CustomExampleNotifier extends StateNotifier<CustomExampleState>
    with PagedNotifierMixin<String, User, CustomExampleState> {
```

You could for example pass an Enum:

```dart
class CustomExampleNotifier extends StateNotifier<CustomExampleState>
    with PagedNotifierMixin<MyEnumType, User, CustomExampleState> {
```

and then just change the Generics of `load` and `RiverPagedBuilder` and your state object that extends `PagedState` to match.

## Custom wrapper for loading/error/try again states

The `RiverPagedBuilder` offers, other than the properties we already saw, the same properties that `infinite_scroll_pagination` offers.

- `firstPageProgressIndicatorBuilder` - a builder for the loading state in the first call
- `newPageProgressIndicatorBuilder` - a builder for the loading state for the subsequent requests
- `firstPageErrorIndicatorBuilder` - a builder for the error state in the first call
- `newPageErrorIndicatorBuilder` - a builder for the error state for the subsequent requests
- `noItemsFoundIndicatorBuilder` - a builder for the empty state in the first call
- `noMoreItemsIndicatorBuilder` - a builder for the empty state for the subsequent request (we have fetched all the items!)

If we need to give a coherent design to our app we could wrap the `RiverPagedBuilder` into a new Widget!

## Testing ##
An integration test is provided demonstrating how easy it is to test this widget:
https://github.com/ftognetto/riverpod_infinite_scroll/blob/main/example/integration_test/app_test.dart
