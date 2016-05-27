classdef SsRandomGazePicker < SsComputation
    % Pick a random point of gaze from a planar scene.
    % Occasionally picks a new gaze target, and scans towards the target at
    % a constant speed.  This is a silly example and not sciencey.
    
    properties
        distance;
        fieldOfView;
        speed;
        updateInterval;
        targetChangeInteval;
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
            parser.addParameter('distance', 2, @isnumeric);
            parser.addParameter('fieldOfView', pi()/24, @isnumeric);
            parser.addParameter('speed', 0.1, @isnumeric);
            parser.addParameter('updateInterval', 0.1, @isnumeric);
            parser.addParameter('targetChangeInteval', 2, @isnumeric);
            parser.parseMagically(obj, varargin{:});
            
            obj.entities.declareSlot(SsSlot('scene').requireClass('SsPlanarScene'));
            obj.outputs.declareSlot(SsSlot('gazePatch').requireClass('SsStream'));
            obj.outputs.declareSlot(SsSlot('gazeTarget').requireClass('SsStream'));
            obj.outputs.declareSlot(SsSlot('gazeBox').requireClass('SsStream'));
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            % choose square region in field of view
            % tan(theta) = opp / adj -> adj * tan(theta) = opp
            scene = obj.entities.findSlot('scene');
            apothem = obj.distance * tan(obj.fieldOfView / 2);
            
            % change the gazeTarget?
            if currentTime >= obj.nextChangeTime
                % uniform-random new gaze target
                obj.targetX = apothem + rand() * (scene.width - apothem);
                obj.targetY = apothem + rand() * (scene.height - apothem);
                
                gazeTarget = obj.outputs.findSlot('gazeTarget');
                gazeTarget.putSample([obj.targetX, obj.targetY], currentTime);
                
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
            
            % make a box around the current gaze
            left = obj.gazeX - apothem;
            right = obj.gazeX + apothem;
            top = obj.gazeY - apothem;
            bottom = obj.gazeY + apothem;
            
            gazeBox = obj.outputs.findSlot('gazeBox');
            gazeBox.putSample([left, right, top, bottom], currentTime);
            
            % ask the scene for the chosen region, clipped to bounds
            gazeImage = scene.sampleRegion(left, right, top, bottom);
            
            % send values out on streams
            gazePatch = obj.outputs.findSlot('gazePatch');
            gazePatch.putSample(gazeImage, currentTime);
            
            % use a constant sampling time
            nextTime = currentTime + obj.updateInterval;
            
            % always OK to run this in parallel
            independenceTime = 0;
        end
    end
end
