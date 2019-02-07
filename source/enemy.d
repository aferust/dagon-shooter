module enemyctrl;

import dagon;
import std.math : sin, PI;
import std.stdio;

// this module is not used yet

class EnemyController: EntityController {
    
    this(Entity e){
        super(e);
    }
    
    override void update(double dt){
        float zz = entity.position.z;
        float xx = 2.0f * sin(zz * 20.0f * PI / 180.0f); // y = amplitude * sin(x * period * pi / 180)
        
        Vector3f right = Vector3f(xx, 0.0f, 0.0f);
        Vector3f forward = Vector3f(0.0f, 0.0f, -2.0f);
        
        float speed = 10.0f;
        Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f);
        dir += forward;
        dir += right;
        
        entity.position += dir.normalized * speed * dt;
        
        //writeln(entity.position.x);
    }
}
