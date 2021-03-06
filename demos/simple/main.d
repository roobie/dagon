module main;

import std.stdio;
import dagon;

// A Scene is a main logical unit in Dagon.
// You can think of it, for example, as a game level:
// it has its own set of assets, entities and other data.
// It also defines its own event handlers and has full
// control over current OpenGL context.
class MyScene: Scene
{
    RenderingContext rc3d; 
    Freeview freeview;

    DynamicArray!Entity entities;
    TextureAsset tex;

    // Constructor is usually called only once
    // at application startup
    this(SceneManager smngr)
    {
        super(smngr);
        assetManager.liveUpdate = true;
    }

    // onAssetsRequest is called just before loading assets
    override void onAssetsRequest()
    {
        tex = addTextureAsset("data/textures/crate.jpg");
    }

    Entity createEntity3D()
    {
        Entity e = New!Entity(eventManager, this);
        return e;
    }

    // onAllocate is called after assets loading.
    // Use this method to create your Entities and other game objects.
    override void onAllocate()
    {    
        freeview = New!Freeview(eventManager, this);
        freeview.camera.setZoom(6.0f);

        ShapeBox shapeBox = New!ShapeBox(1, 1, 1, this);

        auto box = createEntity3D();
        box.drawable = shapeBox;
        entities.append(box);
    }
    
    // onRelease is called when sceneManager.loadAndSwitchToScene
    // is called with releaseCurrentScene set to true.
    // This is a good place to delete the objects allocated in onAllocate.
    // Remember that you actually don't have to (and shouldn't) manually delete 
    // scene's owned objects
    override void onRelease()
    {
        entities.free();
    }

    // onStart is called after (or instead of) loading and allocating.
    // It is always called when switching current scene
    override void onStart()
    {
        writeln("Allocated memory after scene switch: ", allocatedMemory);

        rc3d.init(eventManager);
        rc3d.projectionMatrix = perspectiveMatrix(60.0f, eventManager.aspectRatio, 0.1f, 100.0f);
    }

    // onEnd is called just before releasing and switching current scene
    override void onEnd()
    {
    }

    // onKeyDown is called when the user presses a key
    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            exitApplication();
    }

    // onUpdate is called every frame before rendering
    override void onUpdate(double dt)
    {   
        freeview.update(dt);
        freeview.prepareRC(&rc3d);

        foreach(e; entities)
            e.update(dt);
    }

    // onRender is called when the scene needs to be drawn
    // to the framebuffer 
    override void onRender()
    {     
        glEnable(GL_DEPTH_TEST);

        glViewport(0, 0, eventManager.windowWidth, eventManager.windowHeight);
        glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        rc3d.apply();

        tex.texture.bind();
        foreach(e; entities)
            e.render(&rc3d);
        tex.texture.unbind(); 
    } 
}

class MyApplication: SceneApplication
{
    this(string[] args)
    {
        super(800, 600, "Dagon Demo Application", args);

        MyScene scene = New!MyScene(sceneManager);
        sceneManager.addScene(scene, "MyScene");
        sceneManager.loadAndSwitchToScene("MyScene");
    }
}

void main(string[] args)
{
    writeln("Allocated memory at start: ", allocatedMemory);
    MyApplication app = New!MyApplication(args);
    app.run();
    Delete(app);
    writeln("Allocated memory at end: ", allocatedMemory);
}

