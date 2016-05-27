%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% 2016 isetbio team

clear
clc
close all

%% Use a Gabor patch to interpolate between two spectra.
gabor = SsGaborPatch( ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/6, ...
    'gain', 0.75);

% use 3-plane spectra so we can treat them as rgb
interpolated = SsTwoSpectrumImage( ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
interpolated.nested.offerSlot('weights', gabor);


%% Plug the interpolated reflectance into a flat scene.
scene = SsPlanarScene( ...
    'illuminant', SsSpectrum(1:3, 'magnitudes', [.5 .5 .5]));
scene.nested.offerSlot('reflectance', interpolated);


%% Get out a multispectral radiance image.
radiance = scene.sampleWholeScene();


%% View the radiance image as rgb.
figure()
imshow(radiance, [0 1]);
hold on
targetLine = line(0, 0, ...
    'Marker', '+', ...
    'MarkerSize', 10, ...
    'Color', [0 1 0]);
boxLine = line(0, 0, ...
    'LineStyle', '-', ...
    'LineWidth', 3, ...
    'Color', [0 1 0]);
hold off


%% Compute some random Gazes.
gazePicker = SsRandomGazePicker();
gazePicker.entities.offerSlot('scene', scene);

gazePatch = SsStream();
gazePicker.outputs.offerSlot('gazePatch', gazePatch);
gazeTarget = SsStream();
gazePicker.outputs.offerSlot('gazeTarget', gazeTarget);
gazeBox = SsStream();
gazePicker.outputs.offerSlot('gazeBox', gazeBox);

% For viewing purposes, make simulation time ~= wall time
duration = 5;
tic();
previousTime = 0;
currentTime = 0;

figure();
while currentTime < duration
    % let the computation update itself
    nextTime = gazePicker.update(currentTime, previousTime);
    
    % where are we looking?
    target = gazeTarget.currentValue();
    set(targetLine, ...
        'XData', target(1) * size(radiance, 2), ...
        'YData', target(2) * size(radiance, 1));
    box = gazeBox.currentValue();
    set(boxLine, ...
        'XData', box([1 1 2 2 1]) * size(radiance, 2), ...
        'YData', box([3 4 4 3 3]) * size(radiance, 1));
    
    % what are we looking at?
    patch = gazePatch.currentValue();
    imshow(patch, [0 1]);
    
    % wait wall time approx the same as the simulation time
    pause(nextTime - currentTime);
    previousTime = currentTime;
    currentTime = nextTime;
end
