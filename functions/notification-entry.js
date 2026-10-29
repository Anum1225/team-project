'use strict';
require('firebase-admin/app').initializeApp();
Object.assign(exports, require('./src/notifications'));
Object.assign(exports, require('./src/security/email-security'));
