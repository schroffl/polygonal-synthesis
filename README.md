A very crude attempt at implementing `Polygonal Waveform Synthesis` (see References) using the [`zig-vst` library](https://github.com/schroffl/zig-vst).
There's a lot of things left to do before a usable comes out of this, but it's been a very interesting journey so far.

### References

  * [Continuous Order Polygonal Waveform Synthesis](https://quod.lib.umich.edu/cgi/p/pod/dod-idx/continuous-order-polygonalwaveform-synthesis.pdf?c=icmc;idno=bbp2372.2016.104;format=pdf)
  * [Efficient Anti-Aliasing of a Complex Polygonal Oscillator](http://dafx17.eca.ed.ac.uk/papers/DAFx17_paper_100.pdf)

I built a very basic visualization tool to get a grasp of everything. I'm not sure if that's 100% correct, but you can find it here: https://schroffl.github.io/polygonal-synthesis/

Here's a lissajous graph recording that was made using [schroffl/zig-analyzer-vst](https://github.com/schroffl/zig-analyzer-vst)

![Lissajous Graph of the signal output](docs/lissajous.gif)
