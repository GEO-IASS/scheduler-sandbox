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
            parser.addParameter('title', 'patch', @ischar);
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            slots(1) = SsSlot() ...
                .assignAs('gazePatch') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazePatch');
        end
        
        function afterSlotAssignments(obj, slots)
            obj.initialize();
        end
        
        function initialize(obj)
            % plot the scene image as background
            obj.fig = figure('Name', obj.title);
            obj.ax = axes('Parent', obj.fig);
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            % reposition the gaze target marker
            patch = obj.gazePatch.currentValue();
            imshow(patch, [0 1], 'Parent', obj.ax);
            
            % use a constant sampling time
            nextTime = currentTime + .1;
            
            % always OK to run this in parallel
            independenceTime = 0;
        end
    end
end
