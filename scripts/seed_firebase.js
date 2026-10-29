'use strict';

// Production data must be entered through the authenticated marketplace.
// Historical demo seeding is intentionally disabled: it targeted the live project.
console.error('Demo seeding is disabled. Use the isolated Firebase emulator tests for fixture data.');
process.exitCode = 1;
