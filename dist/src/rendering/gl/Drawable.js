import { gl } from '../../globals';
class Drawable {
    constructor() {
        this.count = 0;
        this.idxBound = false;
        this.posBound = false;
        this.norBound = false;
        this.uvBound = false;
    }
    destory() {
        gl.deleteBuffer(this.bufIdx);
        gl.deleteBuffer(this.bufPos);
        gl.deleteBuffer(this.bufNor);
        gl.deleteBuffer(this.bufUV);
    }
    generateIdx() {
        this.idxBound = true;
        this.bufIdx = gl.createBuffer();
    }
    generatePos() {
        this.posBound = true;
        this.bufPos = gl.createBuffer();
    }
    generateNor() {
        this.norBound = true;
        this.bufNor = gl.createBuffer();
    }
    generateUV() {
        this.uvBound = true;
        this.bufUV = gl.createBuffer();
    }
    bindIdx() {
        if (this.idxBound) {
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
        }
        return this.idxBound;
    }
    bindPos() {
        if (this.posBound) {
            gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
        }
        return this.posBound;
    }
    bindNor() {
        if (this.norBound) {
            gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
        }
        return this.norBound;
    }
    bindUV() {
        if (this.uvBound) {
            gl.bindBuffer(gl.ARRAY_BUFFER, this.bufUV);
        }
        return this.uvBound;
    }
    elemCount() {
        return this.count;
    }
    drawMode() {
        return gl.TRIANGLES;
    }
}
;
export default Drawable;
//# sourceMappingURL=Drawable.js.map