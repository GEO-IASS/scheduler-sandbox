%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% For this example, let our "slot context" do all the wiring up of objects.
% This will work out because our objects have declared "slots" that give
% enough information to decide what should be plugged in, where.
%
% 2016 isetbio team

clear
clc

%% Context holds our objects and wires them up.
context = SsSlotContext();

%% Some entities.

% use Gabor patch as spatial pattern
gabor = SsGaborPatch( ...
    'name', 'gabor', ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/12, ...
    'gain', 0.75);
context.add(gabor);

% define endpoints of color modulation
spectralGabor = SsTwoSpectrumImage( ...
    'name', 'spectralGabor', ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
context.add(spectralGabor);

% plug the spatio-chromatic modulation into a flat scene with pixels
scene = SsPlanarScene( ...
    'name', 'scene', ...
    'illuminant', SsSpectrum(1:3, 'magnitudes', [.5 .5 .5]), ...
    'width', 10, ...
    'height', 10, ...
    'horizontalOffset', -5, ...
    'verticalOffset', -5, ...
    'pixelWidth', 500, ...
    'pixelHeight', 500);
context.add(scene);

% how will we view the scene?
pov = SsPointOfView( ...
    'name', 'pov', ...
    'fieldOfView', pi()/6, ...
    'distance', 1);
context.add(pov);

%% A point of gaze computation and its output streams.

% SsRandomGazePicker provides 3 outputs:
%   "gazeTarget" is a point in the scene, we move gaze towards it
%   "gazeBox" is our current gaze region
%   "gazePatch" is the pixel image within the gaze box
gazePicker = SsRandomGazePicker( ...
    'name', 'gazePicker', ...
    'speed', 3, ...
    'targetChangeInteval', 1);
context.add(gazePicker);

% context will create streams based on slot declarations in SsRandomGazePicker

%% Downstream computation for plotting.
gazePlotter = SsGazePlotter('name', 'gazePlotter');
context.add(gazePlotter);

%% Scheduler to wrangle computation updates.
scheduler = SsTicTocScheduler();
context.add(scheduler);

%% Take a look at what the auto-wiring does.
context.plugInSlots();
ssPlotSlots(context);

%% Simulate some random gazes.
scheduler.initialize();
scheduler.initializeComputations();
scheduler.run(5);

%% Add a new plotter and go again.
context.add(SsPatchPlotter('name', 'patchPlotter'));
context.plugInSlots();
ssPlotSlots(context);

scheduler.initialize();
scheduler.initializeComputations();
scheduler.run(5);

