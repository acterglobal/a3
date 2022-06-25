# Riverpod Infinite Scroll

Hi! This package is a plugin for [infinite_scroll_pagination](https://pub.dev/packages/infinite_scroll_pagination) that is designed to work with [Riverpod](https://riverpod.dev).

# How it works

This package exports a widget, the `RiverPagedBuilder` that will build your infinite, scrollable list.

The `RiverPagedBuilder` expects a Riverpod `StateNotifierProvider` 

This `StateNotifierProvider` must have a few things to ensure everything works correctly, it must have a `load method` and it must have a state that has the list of the elements, an error, and a variable that hold the next page that the load function will use, examples are below.

`riverpod_infinite_scroll` helps us to ensure that our `StateNotifier` will respect these constraints with the choice of two classes:

You can either use the simple: 
 - `PagedState` - a state that has all the properties that `riverpod_infinite_scroll` needs

Or if you need more flexbility you can implement 
 - `PagedNotifierMixin` - a mixin that ensure the `StateNotifier` will implement the right `load` method

## Example - Simple version

Let's see an example now! We have an API that returns a list of `Post` objects, this API is paginated and we need to show a feed displaying those Posts.

The widget we will use for displaying such a feed is `RiverPagedBuilder!`

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

As we can see `RiverPagedBuilder` is really small and easy to implement with the following properties:

 1. `firstPageKey` - the first page we will ask to our paginated api
 2. `provider` - The `StateNotifierProvider` that holds the logic and the list of Posts
 3. `itemBuilder` - a function that build a single Post
 4. `pagedBuilder` - The type of list we want to render. This can be any of the `infinite_scroll_pagination` widgets, and this package already give us the `PaginationController` and the `BuilderDelegate`

Let's see now how the `StateNotifier` we are using works.

Here is our model `Post`:

```dart
    class  Post {
      final  int  id;
      final  String  title;
      final  String  image;
      const  Post({ required  this.id, required  this.title, required  this.image });
    }
```
And the `StateNotifier`

```dart
    class EasyExampleNotifier extends PagedNotifier<int, Post> {

      EasyExampleNotifier():
      super(
        load: (page, limit) => Future.delayed(const  Duration(seconds: 2), () {
          // This simulates a network call to an api that returns paginated posts
          return [
          const  Post(id: 1, title: "My first work", image: "https://www.mywebsite.com/image1"),
          const  Post(id: 2, title: "My second work", image: "https://www.mywebsite.com/image2"),
          const  Post(id: 3, title: "My third work", image: "https://www.mywebsite.com/image3"),
          ];
        }),
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

    final  easyExampleProvider = StateNotifierProvider<EasyExampleNotifier, PagedState<int, Post>>((_) => EasyExampleNotifier());
```

We can extend `PagedNotifier` instead of `StateNotifier` and everything will be done for us.

The `PagedNotifier` only asks for a load function, and a function `nextPageKeyBuilder` that returns the next page to ask. And that's all.

 In the example above we used `NextPageKeyBuilderDefault.mysqlPagination`
 a default function that the package give us to reduce the boilerplate.

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
Let's suppose we need to fetch from a paginated API that return a list of users:

```dart
    class CustomExample extends StatelessWidget {
      const CustomExample({Key? key}) : super(key: key);
  
      @override
      Widget  build(BuildContext  context) {
        return  Scaffold(
          appBar: AppBar(),
          body: RiverPagedBuilder<String, User>(
            firstPageKey: '',
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

> We have used a `PagedGridView` here instead of a `PagedListView` only to make things more fun and to see that this package works with any of the `infinite_scroll_pagination` widgets.

Now let's have a look of how we can create a more custom `StateNotifier`, we have a simple class to represent a User:

```dart 
    class  User {
      final  String  id;
      final  String  name;
      final  String  profilePicture;
      const  User({ required  this.id, required  this.name, required  this.profilePicture });
    }
```
And we have the `StateNotifier` that manages those users
      
```dart    
    class CustomExampleNotifier extends  StateNotifier<CustomExampleState> with  PagedNotifierMixin<String, User, CustomExampleState> {

    CustomExampleNotifier() :
	    super(const  CustomExampleState());
    
	    @override
	    Future<List<User>?> load(String  page, int  limit) async {
          try {
            var  users = await  Future.delayed(const  Duration(seconds: 3), () {
              // This simulates a network call to an api that returns paginated users
              return [
                const  User(id: "abcdef", name: "John", profilePicture: "https://www.mywebsite.com/images/1"),
                const  User(id: "asdfgh", name: "Mary", profilePicture: "https://www.mywebsite.com/images/2"),
                const  User(id: "qwerty", name: "Robert", profilePicture: "https://www.mywebsite.com/images/3")
              ];
            });
        
          // we then update state accordingly
            state = state.copyWith(
              records: [...(state.records ?? []), ...users],
              nextPageKey: users.length < limit ? null : users[users.length - 1].id
            );
          }
          catch (e) {
            // in case of error we should notifiy the listeners
            state = state.copyWith(
              error: e.toString()
            );
          }
	    }

	    // Super simple example of custom methods of the StateNotifier
	    void  add(User  user) {
		    state = state.copyWith(records: [ ...(state.records ?? []), user ]);
	    }
	    
	    void  delete(User  user) {
		    state = state.copyWith(records: [ ...(state.records ?? []) ]..remove(user));
	    }
    }
    
    final  customExampleProvider = StateNotifierProvider<CustomExampleNotifier, CustomExampleState>((_) => CustomExampleNotifier());
```

As we see in this case we didn't use `PagedNotifier`, instead we used a normal Riverpod `StateNotifier` with the `PagedNotifierMixin` which ensures the notifier has a correct `load` method.

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

## Custom wrapper for loading/error/try again states

The `RiverPagedBuilder` offers, other than the properties we already saw, the same properties that `infinite_scroll_pagination` offers.

 - `firstPageProgressIndicatorBuilder` - a builder for the loading state in the first call
 - `newPageProgressIndicatorBuilder` - a builder for the loading state for the subsequent requests
 - `firstPageErrorIndicatorBuilder` - a builder for the error state in the first call
 - `newPageErrorIndicatorBuilder` -  a builder for the error state for the subsequent requests
 - `noItemsFoundIndicatorBuilder` -  a builder for the empty state in the first call
 - `noMoreItemsIndicatorBuilder` - a builder for the empty state for the subsequent request (we have fetched all the items!)
 
If we need to give a coherent design to our app we could wrap the `RiverPagedBuilder` into a new Widget!
