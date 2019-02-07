import std.stdio;

import dagon;
import mainscene;

void main(string[] args)
{
	ShooterApplication app = New!ShooterApplication(args);
    app.run();
    Delete(app);
}
