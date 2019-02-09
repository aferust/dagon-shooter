/*
Copyright (c) 2019-2019 Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:
The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module mainscene;

import std.stdio;
import std.random;
import std.math;
import std.math : sin, PI;
import std.algorithm;
import std.format;
import dagon;
import soloud;
import enemyctrl;

// Ship model is from Angel David Guzmán - PixelOz. Credit to PixelOz Designs

struct Circle {
    float radius;
    float x;
    float z;
}

enum BulletStat{
    ACTIVE,
    PASSIVE
}

class MainScene: Scene
{
    OBJAsset aOBJBullet;
    OBJAsset shipAsset;
    OBJAsset enemyOBJ;
    
    Material rayleighSkyMaterial;
    
    TextureAsset aTexGroundDiffuse;
    TextureAsset aTexGroundNormal;
    TextureAsset aTexGroundHeight;
    TextureAsset aTexGroundRoughness;
    TextureAsset aHeightmap;
    
    TextureAsset shipTexture;
    TextureAsset jetParticleTex;
    TextureAsset boomParticleTex;
    
    Vector3f terrainSize;
    
    Entity eSky;
    Entity eTerrain1, eTerrain2, eTerrain3;
    Entity ship;
    Entity bullets;
    Entity enemies;
    Entity booms;
    Entity eCamera;
    
    float terrainYoffset;
    
    LightSource sun;
    
    FirstPersonView fpview;
    
    float stepRotation;
    immutable float rotMagnitude; 
    bool isrleft, isrright;
    
    double bullet_delayer, enemy_delayer;
    
    Soloud soloud;
    WavStream bang;
    
    NuklearGUI gui;
    TextLine scoreText;
    FontAsset aFontDroidSans20;
    
    uint score = 0;
    
    Material bulletmat;
    Material boomMat;
    
    this(SceneManager smngr)
    {
        super(smngr);
        
        bullet_delayer = 0;
        enemy_delayer = 0;
        
        isrleft = false; isrright = false;
        stepRotation = 0.0f; rotMagnitude = 3.0f;
        
        loadSoloud();
        soloud = Soloud.create();
        soloud.init(Soloud.CLIP_ROUNDOFF | Soloud.LEFT_HANDED_3D);
        bang = WavStream.create();
        bang.load("data/laser_shot_silenced.ogg");
        bang.set3dDistanceDelay(true);
        
        terrainYoffset = -15.0f;
    }
    
    ~this(){
        bang.free();
        soloud.deinit();
        writeln("soloud is free!");
    }
    
    override void onAssetsRequest(){   
        aTexGroundDiffuse = addTextureAsset("data/terrain/desert-albedo.png");
        aTexGroundNormal = addTextureAsset("data/terrain/desert-normal.png");
        aTexGroundHeight = addTextureAsset("data/terrain/desert-height.png");
        aTexGroundRoughness = addTextureAsset("data/terrain/desert-roughness.png");
        aHeightmap = addTextureAsset("data/terrain/heightmap.png");
        
        shipAsset = addOBJAsset("data/ship/ship.obj");
        shipTexture = addTextureAsset("data/ship/shiptexture.png");
        
        enemyOBJ = addOBJAsset("data/suzanne.obj");
        
        aOBJBullet = addOBJAsset("data/bullet/bullet.obj");
        
        aFontDroidSans20 = addFontAsset("data/font/DroidSans.ttf", 20);
        
        jetParticleTex = addTextureAsset("data/particle/jetparticle16.png");
        
        boomParticleTex = addTextureAsset("data/particle/boom32.png");
    }
    
    void prepareShip(){
        ship.drawable = shipAsset.mesh;
        auto shipmat = createMaterial();
        shipmat.diffuse = shipTexture.texture;
        ship.material = shipmat;
        
        ship.position = Vector3f(0.0f, 2.0f, 0.0f);
        
        auto mParticlesJet = createParticleMaterial();
        mParticlesJet.diffuse = jetParticleTex.texture;
        //mParticlesJet.particleSphericalNormal = true;
        mParticlesJet.blending = Transparent;
        mParticlesJet.depthWrite = false;
        mParticlesJet.energy = 1.0f;
        
        Entity[4] eJets;
        
        foreach(i, eJet; eJets){
            eJet = createEntity3D(ship);
            auto emitterJet = New!Emitter(eJet, particleSystem, 10);
            emitterJet.material = mParticlesJet;
            emitterJet.startColor = Color4f(0.5, 1, 1, 0.5f);
            emitterJet.endColor = Color4f(0.3, 0.8, 1, 0.0f);
            emitterJet.initialDirection = Vector3f(0.0f, 0.0f, -0.005f);
            //emitterJet.initialPositionRandomRadius = 0.02f;
            emitterJet.initialDirectionRandomFactor = 0.001f;
            emitterJet.scaleStep = Vector3f(0, 0, 0);
            emitterJet.minInitialSpeed = 100;
            emitterJet.maxInitialSpeed = 110;
            emitterJet.minLifetime = 0.029f;
            emitterJet.maxLifetime = 0.034f;
            emitterJet.minSize = 0.04f;
            emitterJet.maxSize = 0.2f;
            emitterJet.airFrictionDamping = 10.0f;
            eJet.visible = true;
            
            switch (i){
                case 0: eJet.position = ship.position + Vector3f(0.32, -1.55, -1.60);break;
                case 1: eJet.position = ship.position + Vector3f(-0.32, -1.55, -1.60);break;
                case 2: eJet.position = ship.position + Vector3f(0.32, -2.25, -1.60);break;
                case 3: eJet.position = ship.position + Vector3f(-0.32, -2.25, -1.60);break;
                default: break;
            }
        }
        
        
        
    }
    
    override void onAllocate(){
        super.onAllocate();
        
        environment.sunEnergy = 15.0f;
        sun = createLightSun(Quaternionf.identity, environment.sunColor, environment.sunEnergy);
        sun.shadow = true;
        environment.sunRotation =
            rotationQuaternion(Axis.y, degtorad(-45.0f)) *
            rotationQuaternion(Axis.x, degtorad(-75.0f));
        mainSun = sun;
        
        // I need a fixed camera view invariant from mouse movements.
        // for now just don't touch damn mouse!
        eCamera = createEntity3D();
        eCamera.position = Vector3f(0.0f, 15.0f, -15.0f);
        fpview = New!FirstPersonView(eventManager, eCamera, assetManager);
        fpview.camera.turn = -180.0f;
        fpview.camera.pitch = 25.0f; // Is there any lookAt(position) function?
        fpview.active = true;
        view = fpview;
        
        //view = New!Freeview(eventManager, assetManager);

        ship = createEntity3D(); // TODO: need an original 3D model
        prepareShip();
        
        
        // Sky entity
        auto rRayleighShader = New!RayleighShader(assetManager);
        rayleighSkyMaterial = createMaterial(rRayleighShader);
        eSky = createSky(rayleighSkyMaterial);
        
        //terrain
        auto matGround = createMaterial();
        matGround.diffuse = aTexGroundDiffuse.texture;
        matGround.normal = aTexGroundNormal.texture;
        matGround.height = aTexGroundHeight.texture;
        matGround.roughness = aTexGroundRoughness.texture;
        matGround.parallax = ParallaxSimple;
        matGround.textureScale = Vector2f(25, 25);
        
        Vector3f terrainScaling = Vector3f(1, 0.5, 1);
        
        eTerrain1 = createEntity3D();
        auto heightmap = New!OpenSimplexHeightmap(assetManager);
        heightmap.tiling = true;
        auto terrain = New!Terrain(256, 80, heightmap, assetManager);
        //New!ImageHeightmap(aHeightmap.texture.image, 20, assetManager);
        terrainSize = Vector3f(255, 0, 255) * terrainScaling;
        
        eTerrain1.drawable = terrain;
        eTerrain1.position = Vector3f(-terrainSize.x * 0.5, terrainYoffset, -terrainSize.z * 0.5);
        eTerrain1.solid = true;
        eTerrain1.material = matGround;
        eTerrain1.dynamic = false;
        eTerrain1.scaling = terrainScaling;
        
        eTerrain2 = createEntity3D();
        eTerrain2.drawable = terrain;
        eTerrain2.position = Vector3f(-terrainSize.x * 0.5, terrainYoffset, -terrainSize.z * 0.5 + terrainSize.z);
        eTerrain2.solid = true;
        eTerrain2.material = matGround;
        eTerrain2.dynamic = false;
        eTerrain2.scaling = terrainScaling;
        
        eTerrain3 = createEntity3D();
        eTerrain3.drawable = terrain;
        eTerrain3.position = Vector3f(-terrainSize.x * 0.5, terrainYoffset, -terrainSize.z * 0.5 + 2*terrainSize.z);
        eTerrain3.solid = true;
        eTerrain3.material = matGround;
        eTerrain3.dynamic = false;
        eTerrain3.scaling = terrainScaling;
        
        //auto eGround = createEntity3D();
        //eGround.drawable = New!ShapePlane(50, 50, 1, assetManager);
        //eGround.material = matGround;
        
        
        bullets = createEntity3D();
        enemies = createEntity3D();
        booms = createEntity3D();
        
        bulletmat = createMaterial();
        bulletmat.diffuse = Color4f(1.0f, 0.0f, 0.0f, 1.0f);
        bulletmat.emission = Color4f(1.0f, 0.0f, 1.0f, 1.0f);
        
        gui = New!NuklearGUI(eventManager, assetManager);
        auto eNuklear = createEntity2D();
        eNuklear.drawable = gui;
        scoreText = New!TextLine(aFontDroidSans20.font, "0", assetManager);
        scoreText.color = Color4f(0.5f, 0.5f, 0.0f, 0.8f);
        auto eText = createEntity2D();
        eText.drawable = scoreText;
        eText.position = Vector3f(16.0f, 30.0f, 0.0f);
        
        // the material for explosion // okay, this needs improvements
        boomMat = createParticleMaterial();
        boomMat.diffuse = boomParticleTex.texture;
        boomMat.particleSphericalNormal = true;
        boomMat.blending = Transparent;
        boomMat.depthWrite = true;
        boomMat.energy = 1.0f;
    }
    
    void fireBullet(){
        auto bullet = createEntity3D(bullets);
        bullet.groupID = BulletStat.ACTIVE;
        bullet.position = ship.position;
        bullet.position.y -= 1.0f; // fix model shift
        bullet.drawable = aOBJBullet.mesh;
        bullet.material = bulletmat;
        bullet.castShadow = false;
        bullet.updateTransformation(0.0);
        
        int voice = soloud.play3d(bang, ship.position.x, ship.position.y, ship.position.z);
        soloud.set3dSourceMinMaxDistance(voice, 1.0f, 50.0f);
        soloud.set3dSourceAttenuation(voice, 2, 1.0f);
        soloud.update3dAudio();
    }
    
    void moveBullets(double dt){
        foreach(bullet; bullets.children){
            Vector3f forward = Vector3f(0.0f, 0.0f, 10.0f);
            float speed = 20.0f;
            Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f);
            dir += forward;
            if(bullet !is null) bullet.position += dir.normalized * speed * dt;
        }
            
    }
    
    void removeBulletsIfOutOfBounds(){
        foreach(bullet; bullets.children){
            if(abs(bullet.position.z - ship.position.z) > 20.0f && bullet !is null){
                bullets.children.removeAt(bullet.id);
                //bullet.release();
                deleteEntity(bullet);
                break;
            }
        }
        
    }
    
    // TODO: Enemies will shoot and collide the ship also.
    void spawnEnemy(){
        auto rnd = Random(unpredictableSeed);
        float myRndXPos = uniform!"[]"(-10.0f, 10.0f, rnd);
        
        auto enemy = createEntity3D(enemies);
        enemy.drawable = enemyOBJ.mesh;
        enemy.position = Vector3f(myRndXPos, 2.0f, 70.0f);
        enemy.rotation = rotationQuaternion(Axis.y, degtorad(180.0f));
        enemy.updateTransformation(0.0);
        
        auto enemyCtrl = New!EnemyController(enemy);
        enemy.controller = enemyCtrl;
    }
    
    void removeEnemiesIfOutOfBounds(){
        foreach(enemy; enemies.children){
            if(enemy.position.z < -10.0f && enemy !is null){
                enemies.children.removeAt(enemy.id);
                //enemy.release();
                deleteEntity(enemy);
                break;
            }
        }
    }
    
    void removeEnemiesIfHit(){
        foreach(bullet; bullets.children)
        foreach(enemy; enemies.children){
            if(isCircleCollision(bullet.position, 1.0f, enemy.position, 2.0f) && bullet.groupID  == BulletStat.ACTIVE){
                
                if(enemy !is null){
                    auto epos = enemy.position;
                    enemies.removeChild(enemy);
                    deleteEntity(enemy);
                    
                    // the bullet will be actually deleted, when it is out of bounds
                    // this is a safe method I've found so far, deleting it here causes crashes. 
                    bullet.groupID = BulletStat.PASSIVE;
                    bullet.visible = false;
                    
                    makeExplosion(epos);
                    
                    score ++;
                    break;
                    
                }
            }
        }
    }
    
    bool isCircleCollision(Vector3f pos1, float radius1, Vector3f pos2, float radius2){
        Circle circle1 = {radius: radius1, x: pos1.x, z: pos1.z};
        Circle circle2 = {radius: radius2, x: pos2.x, z: pos2.z};

        auto dx = circle1.x - circle2.x;
        auto dz = circle1.z - circle2.z;
        auto distance = sqrt(dx * dx + dz * dz);

        if(distance < circle1.radius + circle2.radius){
            return true;
        }
        
        return false;
    }
    
    void makeExplosion(Vector3f pos){
        
        Entity eboom = createEntity3D(booms);
        
        eboom.position = pos;
        
        auto boomCtrl = New!BoomController(eboom, particleSystem, boomMat);
        eboom.controller = boomCtrl;
        
        //TODO: a boom sound will place here.
        
    }
    
    void removeBoomsIfExpired(){ // A scheduled approach can omit this method.
        // this loop causes random crashes.
        foreach(boom; booms.children){
            auto boomCtrl = cast(BoomController)boom.controller;
            if(boomCtrl.lifetime > 0.2){
                boomCtrl.emitterBoom.emitting = false; // how does an emitter to be removed safely? Please note that this line 
                                                       // is not the only reason for crashes.
                booms.removeChild(boom);
                deleteEntity(boom);
                
            }
        }
    }
    
    override void onKeyDown(int key){
        
        if (key == KEY_ESCAPE){
            writeln("bye :)");
            exitApplication();
        }
        
        switch (key){
            case KEY_LEFT:
                isrleft = true; stepRotation = -rotMagnitude;
                break;
            case KEY_RIGHT:
                isrright = true; stepRotation = rotMagnitude;
                break;
            default:
                break;
        }
    }
    
    override void onKeyUp(int key){
        switch (key){
            case KEY_LEFT: isrleft = false; break;
            case KEY_RIGHT: isrright = false; break;
            default: break;
        }
    }
    
    void updateTerrain(double dt){
        float speed = 8.0f;
        Vector3f dirT = Vector3f(0.0f, 0.0f, -1f);
        eTerrain1.position += dirT.normalized * speed * dt;
        eTerrain2.position += dirT.normalized * speed * dt;
        eTerrain3.position += dirT.normalized * speed * dt;
        
        foreach(ter; [eTerrain1, eTerrain2, eTerrain3]){
            if (ter.position.z <= -terrainSize.z)
                ter.position.z = terrainSize.z * 2;
        }
    }
    
    override void onUpdate(double dt){
        super.onUpdate(dt);
        
        soloud.set3dListenerPosition(eCamera.position.x, eCamera.position.y, eCamera.position.z);
        soloud.set3dListenerAt(eCamera.direction.x, eCamera.direction.y, eCamera.direction.z);
        soloud.set3dListenerUp(eCamera.up.x, eCamera.up.y, eCamera.up.z);
        soloud.update3dAudio();
        
        float speed = 10.0f;
        Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f);
        float step = 5.0f;
        
        Vector3f forward = Vector3f(0.0f, 0.0f, step);
        Vector3f right = Vector3f(step, 0.0f, 0.0f);
        
        if (eventManager.keyPressed[KEY_UP]) dir += forward;
        if (eventManager.keyPressed[KEY_DOWN] && ship.position.z > -5.0f) dir += -forward;
        if (eventManager.keyPressed[KEY_LEFT] && ship.position.x < 15.0f) dir += right;
        if (eventManager.keyPressed[KEY_RIGHT]  && ship.position.x > -15.0f) dir += -right;
        
        ship.position += dir.normalized * speed * dt;
        
        updateTerrain(dt);
        
        if(isrleft == true && ship.rotation.z > -0.35f){
            Vector3f angularVelocity = Vector3f(0.0f, 0.0f, stepRotation);
            ship.rotation += 0.5f * Quaternionf(angularVelocity, 0.0f) * ship.rotation * dt;
            ship.rotation.normalize();
        }
        if(isrright == true && ship.rotation.z < 0.35f){
            Vector3f angularVelocity = Vector3f(0.0f, 0.0f, stepRotation);
            ship.rotation += 0.5f * Quaternionf(angularVelocity, 0.0f) * ship.rotation * dt;
            ship.rotation.normalize();
        }
        
        ///////// level the ship again if not moving left or right
        if(ship.rotation.z != 0.0f && isrleft == false && isrright == false){
            Vector3f angularVelocity = Vector3f(0.0f, 0.0f, 50*ship.rotation.z/5.0f);
            ship.rotation -= 0.5f * Quaternionf(angularVelocity, 0.0f) * ship.rotation * dt;
            ship.rotation.normalize();
        }
        
        bullet_delayer += dt;
        
        if (eventManager.keyPressed[KEY_SPACE]) {
            
            if(bullet_delayer > 0.15){
                fireBullet();
                bullet_delayer = 0.0;
            }
            
        }
        
        
        enemy_delayer += dt;
        
        if(enemy_delayer > 1.0){
            spawnEnemy();
            enemy_delayer = 0.0;
        }
        
        removeEnemiesIfHit();
        removeBoomsIfExpired();
        removeEnemiesIfOutOfBounds();
        removeBulletsIfOutOfBounds();
        
        moveBullets(dt);
        
        scoreText.text = format("Score: %s", score);
    }
}

class ShooterApplication: SceneApplication {
    this(string[] args)
    {
        super(1280, 720, false, "Dagon Application", args);
        MainScene test = New!MainScene(sceneManager);
        sceneManager.addScene(test, "MainScene");
        sceneManager.goToScene("MainScene");
    }
}
