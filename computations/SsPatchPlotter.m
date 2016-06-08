classdef SsPatchPlotter < SsComputation & SsSlotTarget
    % Plot an image patch.
    
    properties
        title;
        
        % slotted
        gazePatch;
    end
    
    properties (Access = private)
        fig;
        ax;
    end
    
    methods
        function obj = SsPatchPlotter(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.addParameter('title', 'patch', @ischar);
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            slots(1) = SsSlot() ...
                .passTo('connectInputStream', 'passSlot', true) ...
                .assignAs('gazePatch') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazePatch');
        end
        
        function initialize(obj)
            % plot the scene image as background
            if isempty(obj.fig) || ~ishghandle(obj.fig)
                obj.fig = figure('Name', obj.title, ...
                    'Units', 'normalized', ...
                    'Position', [0.7 0.6 0.2 0.2]);
            end
            
            if isempty(obj.ax) || ~ishghandle(obj.ax)
                obj.ax = axes('Parent', obj.fig);
            end
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            [nextTime, independenceTime] = obj.update@SsComputation(currentTime, previousTime);
            
            % reposition the gaze target marker
            patch = obj.gazePatch.currentValue();
            imshow(patch, [0 1], 'Parent', obj.ax);
        end
    end
end
