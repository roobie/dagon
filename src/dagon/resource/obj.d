module dagon.resource.obj;

import std.stdio;
import std.string;
import std.format;

import dlib.core.memory;
import dlib.core.stream;
import dlib.math.vector;
import dlib.geometry.triangle;
import dlib.filesystem.filesystem;
import dlib.filesystem.stdfs;
import derelict.opengl.gl;
import dagon.resource.asset;
import dagon.graphics.mesh;

struct ObjFace
{
    uint[3] v;
    uint[3] t1;
    uint[3] t2;
    uint[3] n;
}

class ObjMesh: Mesh
{
    Vector3f[] vertices;
    Vector3f[] normals;
    Vector2f[] texcoords1;
    Vector2f[] texcoords2;
    ObjFace[] faces;
    uint displayList;

    ~this()
    {
        if (glIsList(displayList))
            glDeleteLists(displayList, 1);

        if (vertices.length)
            Delete(vertices);
        if (normals.length)
            Delete(normals);
        if (texcoords1.length)
            Delete(texcoords1);
        if (texcoords2.length)
            Delete(texcoords2);
        if (faces.length)
            Delete(faces);
    }

    void createDisplayList()
    {
        displayList = glGenLists(1);
        glNewList(displayList, GL_COMPILE);
        
        glBegin(GL_TRIANGLES);
        foreach(f; faces)
        {
            if (normals.length) glNormal3fv(normals[f.n[0]].arrayof.ptr);
            if (texcoords1.length) glTexCoord2fv(texcoords1[f.t1[0]].arrayof.ptr);
            if (vertices.length) glVertex3fv(vertices[f.v[0]].arrayof.ptr);
            
            if (normals.length) glNormal3fv(normals[f.n[1]].arrayof.ptr);
            if (texcoords1.length) glTexCoord2fv(texcoords1[f.t1[1]].arrayof.ptr);
            if (vertices.length) glVertex3fv(vertices[f.v[1]].arrayof.ptr);
            
            if (normals.length) glNormal3fv(normals[f.n[2]].arrayof.ptr);
            if (texcoords1.length) glTexCoord2fv(texcoords1[f.t1[2]].arrayof.ptr);
            if (vertices.length) glVertex3fv(vertices[f.v[2]].arrayof.ptr);
        }
        glEnd();
        
        glEndList();
    }

    int opApply(scope int delegate(Triangle t) dg)
    {
        int result = 0;
        // TODO
/*
        foreach(i, ref v; data)
        {
            result = dg(i, v);
            if (result)
                break;
        }
*/
        return result;
    }

    void update(double dt)
    {
    }

    void render()
    {
        if (glIsList(displayList))
            glCallList(displayList);
    }
}

class OBJAsset: Asset
{
    ObjMesh mesh;

    this()
    {
        mesh = New!ObjMesh();
    }

    ~this()
    {
        if (mesh)
            Delete(mesh);
    }

    override bool loadThreadSafePart(string filename, InputStream istrm, ReadOnlyFileSystem fs, AssetManager mngr)
    {
        uint numVerts = 0;
        uint numNormals = 0;
        uint numTexcoords = 0;
        uint numFaces = 0;

        string fileStr = readText(istrm);
        foreach(line; lineSplitter(fileStr))
        {
            //writeln(line);
            if (line.startsWith("v "))
                numVerts++;
            else if (line.startsWith("vn "))
                numNormals++;
            else if (line.startsWith("vt "))
                numTexcoords++;
            else if (line.startsWith("f "))
                numFaces++;
        }

        if (numVerts)
            mesh.vertices = New!(Vector3f[])(numVerts);
        if (numNormals)
            mesh.normals = New!(Vector3f[])(numNormals);
        if (numTexcoords)
            mesh.texcoords1 = New!(Vector2f[])(numTexcoords);
        if (numFaces)
            mesh.faces = New!(ObjFace[])(numFaces);

    float x, y, z;
    int v1, v2, v3;
    int t1, t2, t3;
    int n1, n2, n3;
    uint vi = 0;
    uint ni = 0;
    uint ti = 0;
    uint fi = 0;

    foreach(line; lineSplitter(fileStr))
    {
        //writeln(line);
        if (line.startsWith("v "))
        {
            if (formattedRead(line, "v %s %s %s", &x, &y, &z))
            {
                mesh.vertices[vi] = Vector3f(x, y, z);
                vi++;
            }
            //else
            //    writeln("error");
        }
        else if (line.startsWith("vn"))
        {
            if (formattedRead(line, "vn %s %s %s", &x, &y, &z))
            {
                mesh.normals[ni] = Vector3f(x, y, z);
                ni++;
            }
            //else
            //    writeln("error");
        }
        else if (line.startsWith("vt"))
        {
            if (formattedRead(line, "vt %s %s", &x, &y))
            {
                mesh.texcoords1[ti] = Vector2f(x, -y);
                ti++;
            }
            //else
            //    writeln("error");
        }
        else if (line.startsWith("vp"))
        {
        }
        else if (line.startsWith("f"))
        {
            if (formattedRead(line, "f %s/%s/%s %s/%s/%s %s/%s/%s", &v1, &t1, &n1, &v2, &t2, &n2, &v3, &t3, &n3))
            {
                mesh.faces[fi].v[0] = v1-1;
                mesh.faces[fi].v[1] = v2-1;
                mesh.faces[fi].v[2] = v3-1;
                
                mesh.faces[fi].t1[0] = t1-1;
                mesh.faces[fi].t1[1] = t2-1;
                mesh.faces[fi].t1[2] = t3-1;
                
                mesh.faces[fi].n[0] = n1-1;
                mesh.faces[fi].n[1] = n2-1;
                mesh.faces[fi].n[2] = n3-1;
                
                fi++;
            }
            else if (formattedRead(line, "f %s//%s %s//%s %s//%s", &v1, &n1, &v2, &n2, &v3, &n3))
            {
                mesh.faces[fi].v[0] = v1-1;
                mesh.faces[fi].v[1] = v2-1;
                mesh.faces[fi].v[2] = v3-1;
                
                mesh.faces[fi].n[0] = n1-1;
                mesh.faces[fi].n[1] = n2-1;
                mesh.faces[fi].n[2] = n3-1;
                
                fi++;
            }
            else if (formattedRead(line, "f %s %s %s", &v1, &v2, &v3))
            {
                mesh.faces[fi].v[0] = v1-1;
                mesh.faces[fi].v[1] = v2-1;
                mesh.faces[fi].v[2] = v3-1;
                
                fi++;
            }
            //else
            //    writeln("error");
        }
    }

        Delete(fileStr);
        return true;
    }

    override bool loadThreadUnsafePart()
    {
        mesh.createDisplayList();
        return true;
    }

    override void release()
    {
        if (mesh)
            Delete(mesh);
    }
}

