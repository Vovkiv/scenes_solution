# Scenes Solution
Yet another scene manager.
Can handle scenes stacking, functions across scene, layering and more!

I was not satisfied with available scene managers.
Most of time they lefted umaintained, lack functionality or other reasons.
(Maybe even NIH syndrome...)
So i wrote new one myself. Yay.
Be aware tho: there still be might small bugs here and there or some functionality might be confusing or slow.
That means that if you want to build game from scratch using that lib...(thank you, if you do)
It still might be not the best idea, so play around, make tests before using this library.

Primary functionality of it is:
* Load scenes from files.
* Render them.

But there more:
It have stacking!
It means, that you might simulteniously run several scenes at once (they will be sorted by layer value, that you can change! So you in control what scene should be rendered first!).
It might be useful, for example, when you have game with different levels, but need to show on them the same pause menu, maybe, UI and more!
(Also, you can use it to draw layered levels... don't think it good idea... but it up to you what to render and how!)

For all documentation goto library file itself.
Everything that you need to know about library lies there.

# Demostration video:

https://youtu.be/FScgWYgmUJM

# Simple setup:

1 drop library into your main.lua:

``` local SS = require("scenes_solution") ```

2 Set path to directory with scenes files:

``` SS.path = "/path/to/scenes/```

3 Load scenes:

``` SS.load("scene1", "scene2", "scene3") -- Yes, you can load several files at once, if you need.```

4 Activate needed scenes:

``` SS.activate("scene1", "scene2")```

5 Provide default update/draw dunction:

```
love.update = function(dt)
      SS.call("update", dt)
    end
    
    love.draw = function()
      SS.call("draw")
  end
```
Well, now you need to read documentation for full functionality and start adding game content.
Good luck and with adding scenes to game!
(And don't forget to write about issues, pull requests, help and other!)

# Zerobrane Studio API

Not ready yet.

https://github.com/Vovkiv/scenes_solution
