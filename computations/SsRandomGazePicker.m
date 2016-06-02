classdef SsRandomGazePicker < SsComputation & SsSlotTarget
    % Pick a random point of gaze from a planar scene.
    % Occasionally picks a new gaze target, and scans towards the target at
    % a constant speed.  This is a silly example and not sciencey.
    
    properties
        speed;
        updateInterval;
        targetChangeInteval;
        
        % slotted
        scene;
        pointOfView;
        gazePatch;
        gazeTarget;
        gazeBox;
    end
    
    properties (Access = private)
        nextChangeTime = 0;
        gazeX = 0.5;
        gazeY = 0.5;
        targetX = 0;
        targetY = 0;
    end
    
    methods
        function obj = SsRandomGazePicker(varargin)
            parser = SsInputParser();
            parser.addParameter('speed', 1, @isnumeric);
            parser.addParameter('updateInterval', 0.1, @isnumeric);
            parser.addParameter('targetChangeInteval', 2, @isnumeric);
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            % need a scene and several output streams
            slots(1) = SsSlot() ...
                .assignAs('scene') ...
                .requireClass('SsPlanarScene');
            slots(2) = SsSlot() ...
                .assignAs('pointOfView') ...
                .requireClass('SsPointOfView') ...
                .autocreate(true);
            slots(3) = SsSlot() ...
                .assignAs('gazePatch') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazePatch') ...
                .autocreate(true);
            slots(4) = SsSlot() ...
                .assignAs('gazeTarget') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeTarget') ...
                .autocreate(true);
            slots(5) = SsSlot() ...
                .assignAs('gazeBox') ...
                .requireClass('SsStream') ...
                .preferProperty('name', 'value', 'gazeBox') ...
                .autocreate(true);
        end
        
        function afterSlotAssignments(obj, slots)
            obj.gazePatch.setInput(obj);
            obj.gazeTarget.setInput(obj);
            obj.gazeBox.setInput(obj);
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            % change the gazeTarget?
            if currentTime >= obj.nextChangeTime
                % uniform-random new gaze target
                [left, right, top, bottom] = obj.scene.bounds();
                obj.targetX = left + rand() * (right - left);
                obj.targetY = top + rand() * (bottom - top);
                obj.gazeTarget.putSample([obj.targetX, obj.targetY], currentTime);
                
                % when to move the target next?
                obj.nextChangeTime = currentTime + obj.targetChangeInteval * 2 * rand();
            end
            
            % zero in on the current gaze target
            stepSize = obj.speed * (currentTime - previousTime);
            diffX = obj.targetX - obj.gazeX;
            diffY = obj.targetY - obj.gazeY;
            diffTheta = atan2(diffY, diffX);
            stepX = stepSize * cos(diffTheta);
            stepY = stepSize * sin(diffTheta);
            obj.gazeX = obj.gazeX + stepX;
            obj.gazeY = obj.gazeY + stepY;
            
            % choose square region in field of view
            % tan(theta) = opp / adj -> adj * tan(theta) = opp
            apothem = obj.pointOfView.distance * tan(obj.pointOfView.fieldOfView / 2);
            left = obj.gazeX - apothem;
            right = obj.gazeX + apothem;
            top = obj.gazeY - apothem;
            bottom = obj.gazeY + apothem;
            obj.gazeBox.putSample([left, right, top, bottom], currentTime);
            
            % ask the scene for the chosen region, clipped to bounds
            patch = obj.scene.sampleRegion(left, right, top, bottom);
            obj.gazePatch.putSample(patch, currentTime);
            
            % use a constant sampling time
            nextTime = currentTime + obj.updateInterval;
            
            % always OK to run this in parallel
            independenceTime = 0;
        end
    end
end
