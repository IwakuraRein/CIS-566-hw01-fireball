import { mat4 } from 'gl-matrix';
import { gl } from '../../globals';
var activeProgram = null;
export class Shader {
    constructor(type, source) {
        this.shader = gl.createShader(type);
        gl.shaderSource(this.shader, source);
        gl.compileShader(this.shader);
        if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
            throw gl.getShaderInfoLog(this.shader);
        }
    }
}
;
class ShaderProgram {
    constructor(shaders) {
        this.prog = gl.createProgram();
        for (let shader of shaders) {
            gl.attachShader(this.prog, shader.shader);
        }
        gl.linkProgram(this.prog);
        if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
            throw gl.getProgramInfoLog(this.prog);
        }
        this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
        this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
        this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
        this.attrUV = gl.getAttribLocation(this.prog, "vs_UV");
        this.unifModel = gl.getUniformLocation(this.prog, "u_Model");
        this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
        this.unifViewProj = gl.getUniformLocation(this.prog, "u_ViewProj");
        this.unifColor = gl.getUniformLocation(this.prog, "u_Color");
        this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
        this.unifCellNum = gl.getUniformLocation(this.prog, "u_CellNum");
        this.unifMovingSpeed = gl.getUniformLocation(this.prog, "u_MovingSpeed");
        this.unifPatternSize = gl.getUniformLocation(this.prog, "u_PatternSize");
        this.unifMorphingSpeed = gl.getUniformLocation(this.prog, "u_MorhpingSpeed");
    }
    use() {
        if (activeProgram !== this.prog) {
            gl.useProgram(this.prog);
            activeProgram = this.prog;
        }
    }
    setModelMatrix(model) {
        this.use();
        if (this.unifModel !== -1) {
            gl.uniformMatrix4fv(this.unifModel, false, model);
        }
        if (this.unifModelInvTr !== -1) {
            let modelinvtr = mat4.create();
            mat4.transpose(modelinvtr, model);
            mat4.invert(modelinvtr, modelinvtr);
            gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
        }
    }
    setViewProjMatrix(vp) {
        this.use();
        if (this.unifViewProj !== -1) {
            gl.uniformMatrix4fv(this.unifViewProj, false, vp);
        }
    }
    setGeometryColor(color) {
        this.use();
        if (this.unifColor !== -1) {
            gl.uniform4fv(this.unifColor, color);
        }
    }
    setMovingSpeed(val) {
        this.use();
        if (this.unifMovingSpeed !== -1) {
            gl.uniform1f(this.unifMovingSpeed, val);
        }
    }
    setPatternSize(val) {
        this.use();
        if (this.unifPatternSize !== -1) {
            gl.uniform1f(this.unifPatternSize, val);
        }
    }
    setCellNum(val) {
        this.use();
        if (this.unifCellNum !== -1) {
            gl.uniform1f(this.unifCellNum, val);
        }
    }
    setMorphingSpeed(val) {
        this.use();
        if (this.unifMorphingSpeed !== -1) {
            gl.uniform1f(this.unifMorphingSpeed, val);
        }
    }
    setTime(time) {
        this.use();
        if (this.unifTime !== -1) {
            gl.uniform1f(this.unifTime, time);
        }
    }
    draw(d) {
        this.use();
        if (this.attrPos != -1 && d.bindPos()) {
            gl.enableVertexAttribArray(this.attrPos);
            gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
        }
        if (this.attrNor != -1 && d.bindNor()) {
            gl.enableVertexAttribArray(this.attrNor);
            gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
        }
        if (this.attrUV != -1 && d.bindUV()) {
            gl.enableVertexAttribArray(this.attrUV);
            gl.vertexAttribPointer(this.attrUV, 2, gl.FLOAT, false, 0, 0);
        }
        d.bindIdx();
        gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);
        if (this.attrPos != -1)
            gl.disableVertexAttribArray(this.attrPos);
        if (this.attrNor != -1)
            gl.disableVertexAttribArray(this.attrNor);
        if (this.attrUV != -1)
            gl.disableVertexAttribArray(this.attrUV);
    }
}
;
export default ShaderProgram;
//# sourceMappingURL=ShaderProgram.js.map