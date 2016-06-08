classdef SsComputation < SsSlotTarget
    % Time-varying numerical model with internal state and I/O streams.
    
    properties
        name;
        updateInterval = 0.1;
    end
    
    methods
        function initialize(obj)
            % default is no-op, subclasses may override
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            % chose default update time, subclasses may override
            nextTime = currentTime + obj.updateInterval;
            independenceTime = currentTime + obj.updateInterval;
        end
        
        function isAccepted = connectOutputStream(obj, stream, slot)
            parser = SsInputParser();
            parser.addRequired('stream', @(s) isa(s, 'SsStream'));
            parser.addRequired('slot', @(s) isa(s, 'SsSlot'));
            parser.parseMagically('caller', stream, slot);
            
            isAccepted = obj.assignProperty(slot.assignmentTarget, stream);
            if ~isAccepted
                return;
            end
            
            % let the stream know who is "upstream", feeding inputs to it
            stream.input = obj;
        end
        
        function isAccepted = connectInputStream(obj, stream, slot)
            parser = SsInputParser();
            parser.addRequired('stream', @(s) isa(s, 'SsStream'));
            parser.addRequired('slot', @(s) isa(s, 'SsSlot'));
            parser.parseMagically('caller', stream, slot);
            
            isAccepted = obj.assignProperty(slot.assignmentTarget, stream);
            if ~isAccepted
                return;
            end
        end
    end
end
