module enemyctrl;

import dagon;
import std.math : sin, PI;
import std.stdio;

import dlib.math.matrix;
import dlib.math.transformation;

class EnemyController: EntityController {
    
    this(Entity e){
        super(e);
    }
    
    override void update(double dt){
        float zz = entity.position.z;
        float amplitude = 2.0f;
        float period = 20.0f;
        
        float xx = amplitude * sin(zz * period * PI / 180.0f);
        
        Vector3f right = Vector3f(xx, 0.0f, 0.0f);
        Vector3f forward = Vector3f(0.0f, 0.0f, -4.0f);
        
        float speed = 20.0f;
        Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f);
        dir += forward;
        dir += right;
        
        entity.position += dir.normalized * speed * dt;
        
        entity.transformation =
            translationMatrix(entity.position) *
            entity.rotation.toMatrix4x4 *
            scaleMatrix(entity.scaling);

        entity.invTransformation = entity.transformation.inverse;
        
    }
}


// A tween/action-based method would be a better approach to schedule an emitter (explode and disappear in given time).
// I don't know how to delete/remove an emitter safely.
// Emitter class has no an id member contrary to Entity. An emitter should be removed from 
// DynamicArray!Emitter emitters of ParticleSystem;
class BoomController: EntityController {
    double lifetime;
    Emitter emitterBoom;
    
    this(Entity e, ParticleSystem particleSystem, Material boomMat){
        super(e);
        
        lifetime = 0.0;
        
        // I admit that this is a terrible explosion. It needs improvements to have
        // more 3D feel.
        emitterBoom = New!Emitter(entity, particleSystem, 10);
        emitterBoom.material = boomMat;
        emitterBoom.startColor = Color4f(0.5, 0.5, 0, 0.5f);
        emitterBoom.endColor = Color4f(0.3, 0.8, 1, 0.0f);
        emitterBoom.initialDirection = Vector3f(1, 1, 1);
        emitterBoom.initialPositionRandomRadius = 0.01f;
        emitterBoom.initialDirectionRandomFactor = 0.01f;
        emitterBoom.scaleStep = Vector3f(0, 0, 0);
        emitterBoom.minInitialSpeed = 80;
        emitterBoom.maxInitialSpeed = 100;
        emitterBoom.minLifetime = 0.01f;
        emitterBoom.maxLifetime = 0.02f;
        emitterBoom.minSize = 1.0f;
        emitterBoom.maxSize = 3.2f;
        emitterBoom.airFrictionDamping = 10.0f;
        entity.visible = true;
    }
    
    override void update(double dt){
        lifetime += dt;
    }
}
