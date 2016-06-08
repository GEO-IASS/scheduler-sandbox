%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% For this example, I'll assign objects to slots explicitly.  Each slot
% will check if the objet I'm offering is a good match for the slot.
%
% 2016 isetbio team

clear
clc

%% Some entities.

% use Gabor patch as spatial pattern
gabor = SsGaborPatch( ...
    'name', 'gabor', ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/12, ...
    'gain', 0.75);

% define endpoints of color modulation
spectralGabor = SsTwoSpectrumImage( ...
    'name', 'spectralGabor', ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
spectralGabor.offer(gabor);

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
scene.offer(spectralGabor);

% how will we view the scene?
pov = SsPointOfView( ...
    'name', 'pov', ...
    'fieldOfView', pi()/6, ...
    'distance', 2);

%% A point of gaze computation and its output streams.

% SsRandomGazePicker provides 3 outputs:
%   "gazeTarget" is a point in the scene, we move gaze towards it
%   "gazeBox" is our current gaze region
%   "gazePatch" is the pixel image within the gaze box
gazePicker = SsRandomGazePicker( ...
    'name', 'gazePicker', ...
    'speed', 3, ...
    'targetChangeInteval', 1);
gazePicker.offer(scene);
gazePicker.offer(pov);

% attach an output stream for each output
gazeTarget = SsStream('name', 'gazeTarget');
gazePicker.offer(gazeTarget);

gazeBox = SsStream('name', 'gazeBox');
gazePicker.offer(gazeBox);

gazePatch = SsStream('name', 'gazePatch');
gazePicker.offer(gazePatch);

%% Downstream computation for plotting.
gazePlotter = SsGazePlotter('name', 'gazePlotter');
gazePlotter.offer(scene);
gazePlotter.offer(gazeTarget);
gazePlotter.offer(gazeBox);

%% Scheduler to wrangle computation updates.
scheduler = SsTicTocScheduler();
scheduler.add(gazePicker);
scheduler.add(gazePlotter);

%% Simulate some random gazes.
scheduler.initialize();
scheduler.initializeComputations();
scheduler.run(5);
