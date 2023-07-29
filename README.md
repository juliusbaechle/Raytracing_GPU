# Raytracing_GPU
Raytracer running with OpenCL on the GPU, which allows me to move fluidly through my scene. 
For each frame, the GPU has to track over eight million rays (even if you leave out refractions and reflections). 
Despite this enormous effort, it runs at 40 to 80 fps on my Intel A370M graphics card.

<img src="doc/Raytracing.png" alt="Raytraing">
