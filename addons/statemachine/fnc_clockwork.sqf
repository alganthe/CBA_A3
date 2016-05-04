/* ----------------------------------------------------------------------------
Function: CBA_statemachine_fnc_clockwork

Description:
    Clockwork which runs all state machines.

Parameters:
    None

Returns:
    Nothing

Author:
    BaerMitUmlaut
---------------------------------------------------------------------------- */
#include "script_component.hpp"
SCRIPT(clockwork);

{
    private _stateMachine = _x;
    private _list = _stateMachine getVariable QGVAR(list);
    private _updateCode = _stateMachine getVariable QGVAR(updateCode);
    private _id = _stateMachine getVariable QGVAR(ID);

    // Skip state machine when it has no states yet
    if !(isNil {_stateMachine getVariable QGVAR(initialState)}) then {
        private _tick = _stateMachine getVariable QGVAR(tick);

        // When the list was iterated through, jump back to start and update it
        if (_tick >= count _list) then {
            _tick = 0;
            if !(_updateCode isEqualTo {}) then {
                _list = [] call _updateCode;
                _stateMachine setVariable [QGVAR(list), _list];
            };
        };

        // If the list has no items, we can stop checking this state machine
        // No need to set the tick when it will get reset next frame anyways
        if (count _list > 0) then {
            _stateMachine setVariable [QGVAR(tick), _tick + 1];

            private _current = _list select _tick;
            private _thisState = _current getVariable [QGVAR(state) + str _id, _stateMachine getVariable QGVAR(initialState)];

            // onState functions can use:
            //   _stateMachine - the state machine
            //   _this         - the current list item
            //   _thisState    - the current state
            _current call (_stateMachine getVariable ONSTATE(_thisState));

            private _thisOrigin = _thisState;
            {
                _x params ["_thisTransition", "_condition", "_thisTarget", "_onTransition"];
                // Transition conditions and onTransition functions can use:
                //   _stateMachine   - the state machine
                //   _this           - the current list item
                //   _thisTransition - the current transition we're in
                //   _thisOrigin     - the state we're coming from
                //   _thisTarget     - the state we're transitioning to
                if (_current call _condition) exitWith {
                    _current call _onTransition;
                    _current setVariable [QGVAR(state) + str _id, _thisTarget];
                };
            } forEach (_stateMachine getVariable TRANSITIONS(_thisState));
        };
    };

    false
} count GVAR(stateMachines);
