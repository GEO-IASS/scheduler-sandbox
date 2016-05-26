%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% 2016 isetbio team

clear
clc

%% Use a Gabor patch to interpolate between two spectra.
gabor = SsGaborPatch( ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/6, ...
    'gain', 0.5);

% use 3-plane spectra so we can treat them as rgb
interpolated = SsTwoSpectrumImage( ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 1 1]));
interpolated.offerSlot('weights', gabor)


%% Plug the interpolated reflectance into a flat scene.
scene = SsPlanarScene( ...
    'illuminant', SsSpectrum(1:3, 'magnitudes', [.25 .5 .75]));
scene.offerSlot('reflectance', interpolated);

%% Get out a multispectral radiance image.
x = linspace(-10, 10, 500);
radiance = scene.sampleGrid(x, x);

%% View the radiance image as rgb.
imshow(radiance, []);
