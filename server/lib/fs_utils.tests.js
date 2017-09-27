// Tests for links methods
//
// https://guide.meteor.com/testing.html

import { Meteor } from 'meteor/meteor';
import { assert } from 'meteor/practicalmeteor:chai';
import { FSDirectory } from './fs_utils.js';

const TEST_DIR = 'c:\\projects\\OurPhotos';
const TEST_BADDIR = 'c:\\projects\\OurPhotosxxx';

if (Meteor.isServer) {
    describe('directory methods', function () {
        beforeEach(function () {
            //Links.remove({});
        });

        it('can see good directory '+TEST_DIR, function () {
            const testDirectory = new FSDirectory(TEST_DIR);
            assert.equal(testDirectory.path(),TEST_DIR);
        });
        it('can fail bad directory '+TEST_BADDIR, function () {
            try {
                const testDirectory = new FSDirectory(TEST_BADDIR);
                //assert.equal(testDirectory.path(), TEST_BADDIR);
            } catch (e) {
                assert.isAbove(e.message.indexOf('not found'),0);
            } finally {
            }
        });
        it('can see subdirectories '+TEST_DIR, function () {
            const testDirectory = new FSDirectory(TEST_DIR);
            assert.isAbove(testDirectory.directories().length,0);
        });
        it('can see subdirectory files '+TEST_DIR, function () {
            const testDirectory = new FSDirectory(TEST_DIR);
            assert.isAbove(testDirectory.directories()[0].files().length,0);
        });
    });
}
