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
        targetLine;
        boxLine;
    end
    
    methods
        function obj = SsGazePlotter(varargin)
            parser = SsInputParser();
            parser.addParameter('title', 'gaze', @ischar);
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            slots(1) = SsSlot() ...
                .assignAs('scene') ...
                .requireClass('SsPlanarScene');
            slots(2) = SsSlot() ...
                .assignAs('gazeTarget') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeTarget');
            slots(3) = SsSlot() ...
                .assignAs('gazeBox') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeBox');
        end
        
        function afterSlotAssignments(obj, slots)
            % plot the scene image as background
            obj.fig = figure('Name', obj.title);
            radiance = obj.scene.sampleWholeScene();
            imshow(radiance, [0 1]);
            
            % lines to update gaze
            hold on
            obj.targetLine = line(0, 0, ...
                'Marker', '+', ...
                'MarkerSize', 10, ...
                'Color', [0 1 0]);
            obj.boxLine = line(0, 0, ...
                'LineStyle', '-', ...
                'LineWidth', 2, ...
                'Color', [0 1 0]);
            hold off
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
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
            
            % use a constant sampling time
            nextTime = currentTime + 1;
            
            % always OK to run this in parallel
            independenceTime = 0;
        end
    end
end
