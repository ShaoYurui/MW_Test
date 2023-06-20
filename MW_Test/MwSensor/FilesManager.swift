//
//  FilesManager.swift
//  AR Gait SPPB
//
//  Created by Jerome Derrick on 5/7/21.
//
import Foundation

class FilesManager: FileManager
{
    let documentsDirectory:URL
    
    override init()
    {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// create folder
    /// - parameter path: folder name
    func createFolder(path:String)
    {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("FilesManager.createFolder error: \(error.localizedDescription)");
        }
    }
    
    /// get list of files in the root directory of the app storage
    /// - returns:  array of file URLs
    func mainDirectoryFiles () throws -> [URL]
    {
        try subDirectoryFiles(path: documentsDirectory)
    }
    
    /// get list files in the directory
    /// - parameter path: directory name
    /// - returns: array of file URLs
    func subDirectoryFiles(path:URL) throws -> [URL]
    {
        try FileManager.default.contentsOfDirectory(at: path.deletingPathExtension(), includingPropertiesForKeys: nil, options: [])
    }
    
    /// get all files starting from path downwards recursively
    /// - parameter path: directory name
    /// - returns: array of file URLs
    func getFiles(path:URL) throws -> [URL]
    {
        var fileList = [URL]()
        if path.hasDirectoryPath {
            for subPath in try subDirectoryFiles(path: path) {
                fileList += try getFiles(path: subPath)
            }
        }
        else {
            fileList = [path]
        }
        return fileList
    }
    
    func deleteA_file(path:URL) throws
    {
        try removeItem(at: path)
    }
}
