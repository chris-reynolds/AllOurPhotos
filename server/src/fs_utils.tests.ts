// Tests for links methods
//

import { assert } from 'chai';
import { FsDirectory } from './fs_utils';

const TEST_DIR = 'c:\\projects\\AllOurPhotos';
const TEST_BADDIR = 'c:\\projects\\AllOurPhotosxxx';


    describe('directory methods', function () {
        beforeEach(function () {
            //Links.remove({});
        });

        it('can see good directory '+TEST_DIR, function () {
            const testDirectory = new FsDirectory(TEST_DIR);
            assert.equal(testDirectory.fullPath,TEST_DIR);
        });
        it('can fail bad directory '+TEST_BADDIR, function () {
            try {
                const testDirectory = new FsDirectory(TEST_BADDIR);
                // after exception this should never be executes
                assert.equal(testDirectory.fullPath+' WAS FOUND', '');
            } catch (e) {
                assert.exists(e.message,'not found');
            } finally {
            }
        });
        it('can see subdirectories '+TEST_DIR, function () {
            const testDirectory = new FsDirectory(TEST_DIR);
            assert.isAbove(testDirectory.directories.length,0);
        });
        it('can see subdirectory files '+TEST_DIR, function () {
            const testDirectory = new FsDirectory(TEST_DIR);
            assert.isAbove(testDirectory.directories[0].files.length,0);
        });
    });

