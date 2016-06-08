classdef SsGazePlotter < SsComputation & SsSlotTarget
    % Plot a gaze box inside a scene.
    
    properties
        title;
        
        % slotted
        scene;
        gazeTarget;
        gazeBox;
    end
    
    properties (Access = private)
        fig;
        ax;
        targetLine;
        boxLine;
    end
    
    methods
        function obj = SsGazePlotter(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.addParameter('title', 'gaze', @ischar);
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            slots(1) = SsSlot() ...
                .assignAs('scene') ...
                .requireClass('SsPlanarScene');
            slots(2) = SsSlot() ...
                .passTo('connectInputStream', 'passSlot', true) ...
                .assignAs('gazeTarget') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeTarget');
            slots(3) = SsSlot() ...
                .passTo('connectInputStream', 'passSlot', true) ...
                .assignAs('gazeBox') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeBox');
        end
        
        function initialize(obj)
            % plot the scene image as background
            if isempty(obj.fig) || ~ishghandle(obj.fig)
                obj.fig = figure('Name', obj.title);
            end
            
            if isempty(obj.ax) || ~ishghandle(obj.ax)
                obj.ax= axes('Parent', obj.fig);
                radiance = obj.scene.sampleWholeScene();
                imshow(radiance, [0 1], 'Parent', obj.ax);
            end
            
            % lines to update gaze
            if isempty(obj.targetLine) || ~ishghandle(obj.targetLine)
                hold on
                obj.targetLine = line(0, 0, ...
                    'Parent', obj.ax, ...
                    'Marker', '+', ...
                    'MarkerSize', 10, ...
                    'Color', [0 1 0]);
                hold off
            end
            if isempty(obj.boxLine) || ~ishghandle(obj.boxLine)
                hold on
                obj.boxLine = line(0, 0, ...
                    'Parent', obj.ax, ...
                    'LineStyle', '-', ...
                    'LineWidth', 2, ...
                    'Color', [0 1 0]);
                hold off
            end
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            [nextTime, independenceTime] = obj.update@SsComputation(currentTime, previousTime);
            
            % reposition the gaze target marker
            target = obj.gazeTarget.currentValue();
            [targetX, targetY] = obj.scene.sceneToPixels(target(1), target(2));
            set(obj.targetLine, ...
                'XData', targetX, ...
                'YData', targetY);
            
            % reposition the gaze box
            box = obj.gazeBox.currentValue();
            [boxX, boxY] = obj.scene.sceneToPixels(box(1:2), box(3:4));
            set(obj.boxLine, ...
                'XData', boxX([1 1 2 2 1]), ...
                'YData', boxY([1 2 2 1 1]));
        end
    end
end
