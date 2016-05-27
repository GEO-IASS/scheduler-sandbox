classdef SsSlotCollection < handle
    % Holder and utilities for multiple Slots.
    
    properties
        slots;
    end
    
    methods
        function declareSlot(obj, slot)
            if isempty(obj.slots)
                obj.slots = slot;
            else
                obj.slots(end+1) = slot;
            end
        end
        
        function accepted = offerSlot(obj, name, offering)
            [~, slot] = obj.findSlot(name);
            if isempty(slot)
                accepted = false;
                return;
            end
            accepted = slot.offer(offering);
        end
        
        function [object, slot] = findSlot(obj, name)
            isNamedSlot = strcmp(name, {obj.slots.name});
            if any(isNamedSlot)
                slot = obj.slots(find(isNamedSlot, 1, 'first'));
                object = slot.object;
            else
                warning('Slotted:noSuchSlot', ...
                    'Slotted object has no slot named "%s".', name);
                slot = [];
                object = [];
            end
        end
    end
end
