HotWire


### Install rails 

rails g scaffold Post title:string body:text
rails db:create RAILS_ENV=development
rails db:migrate RAILS_ENV=development

### Install hotwire

gem 'hotwire-rails'
bundle install 
rails hotwire:install


Step 1:  set broadcast section before any action

Go to Post Model then add this code: `after_create_commit {broadcast_prepend_to "posts"}`


Step 2:  We need to create frame in poxts/index and use same name “posts”
1- Go to the posts/index view.

2- Add this code.

‘’’
<%= turbo_frame_tag "posts" do %>
  <%= render @posts %>
<% end %>
‘’’
That will create tag  `<turbo-frame id="posts">`.

3- Add this style: “app/assets/stylesheets/application.css”, to notice where this tag set.
‘’’
turbo-frame {
  border: 1px solid red;
  padding: 2rem;
  display: block;
}
‘’’

4- Go to `app/controllers/posts_controller.rb#create’  change the successful creation part 
From
```
format.html { redirect_to @post, notice: 'Post was successfully created.' }
```
To
```
format.html { redirect_to posts_url, notice: 'Post was successfully created.' }
```

Step 3: Let’s test create a new post:
```
Processing by PostsController#create as TURBO_STREAM
[ActionCable] Broadcasting to posts: "<turbo-stream action=\"prepend\" target=\"posts\"><template><div>\n  <h3>Test title</h3>\n  <p>test body</p>\n  <a href=\"/posts/9\">Show</a>\n  <a href=\"/posts/9/edit\">Edit</a>\n  <a data-confirm=\"Are you sure?\" rel=\"nofollow\" data-method=\"delete\" href=\"/posts/9\">Destroy</a>\n</div>\n<hr/>\n</template></turbo-stream>"
```
- We have normal redirect `Redirected to http://localhost:3000/posts`
- Processing by PostsController#index as TURBO_STREAM //  only happen after creation TURBO_STREAM 

?? Backend broadcast the new changes , but nothing in the frontend handle this event

Step 4: Add this line in `posts/index` view: 
```
<%= turbo_stream_from “posts” %>
```
Adding a `tube stream from` will set up a line of code in Html, that says “ javascript go and stream form “posts stream” , to that tell the action cable channel to stream the that channel 
>>> Model:post after_create_commit {broadcast_prepend_to "posts”}.

If we check the html Code 
‘’’
<turbo-cable-stream-source channel="Turbo::StreamsChannel" signed-stream-name="InBvc3RzIg==--5f6c4e9c4fbaa8773a01f52613dbbb8d5dbee8d6f66a6e9cfdf7b15746a4c3d9"></turbo-cable-stream-source>
‘’’
Steam tag is going to be monitored and start the stream and close the stream, whenever you move a way from that  page

Let’s test this changes 
Example 1:
- Go to Rials console
- Post.create title: "Hotwire", body: "Hotwire is an alternative approach to building modern web applications without using much JavaScript by sending HTML instead of JSON over the wire"
Example 2: add these lines of code in the Models/Post:
  after_update_commit {broadcast_replace_to "posts"}
  after_destroy_commit {broadcast_remove_to "posts"}

And from Rails console try to destroy:
- Post.last.destroy
- Post.last.update body: "Hey"

We will notice there is no change,  why!! , let’s check the log file.

>> Turbo::StreamsChannel transmitting "<turbo-stream action=\"remove\" target=\"post_22\"></turbo-stream>" (via streamed from posts)
| target=\"post_22\" 
Frontend going to search this Dom id, but it’s not exist   Step 5:  We need to wrap our code with  turbo_frame_tag  “app/views/posts/_post.html.erb”
```
<%= turbo_frame_tag dom_id(post) do %>
……
<% end %>
```

Check html code
```
<turbo-frame id="post_1"></turbo-frame>
```

```
<%= turbo_frame_tag post do %>
……
<% end %>
```

Check html code
<turbo-frame id="#<Post:0x00007f9b87dff0c8>"></turbo-frame>


Step 6: Handling Post in the form:
1- wrap the form prat with in the posts/index
```
<%= turbo_frame_tag ‘post_form’ do %>
<%= render 'form', post: @post %>
<% end %>
```

Try to submit invalid data ( empty form) nothing happen , if we check the log file,

>> Processing by PostsController#create as TURBO_STREAM Rails nothing happen becuse we don’t handle this TURBO_STREAM in the controller 
2- Go to `app/controllers/posts_controller.rb#create’
```
format.turbo_stream { render turbo_stream: turbo_stream.replace(@post, partial: "posts/form", locals: { post: @post}) }
```

3- Go to ‘app/views/posts/_form.html.erb’
```
<%= form_with(model: post, local: true, id: dom_id(post)) do |form| %>
```
If it a new post, form id = ‘new_post’
If it a exist post, form  id = ‘post_1’ 
Check (chrome , console , network)

Check these file:
app/models/concerns/turbo/broadcastable.rb #model function
app/assets/javascripts/turbo.js  (StreamActions: prepend/ append/ remove/update)
