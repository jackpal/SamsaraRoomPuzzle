//
//  main.swift
//  SamsaraRoomPuzzle
//
//  Created by Jack Palevich on 5/1/20.
//  Copyright © 2020 Jack Palevich. All rights reserved.
//
// This solves the bookshelf puzzle in the game Samsara Room.

import Foundation

typealias PieceColor = UInt8

extension PieceColor {
  var colorChar: Character {
    Character(UnicodeScalar(96 + self))
  }

  var letter: String {
    String(colorChar)
  }
}

struct PieceSize : Equatable, Hashable, Comparable {

  static func < (lhs: PieceSize, rhs: PieceSize) -> Bool {
    if lhs.w < rhs.w {
      return true
    }
    if lhs.w > rhs.w {
      return false
    }
    return lhs.h < rhs.h
  }

  let w: Int
  let h: Int

  var description: String {
    "\(w)x\(h)"
  }
}

struct PuzzlePiece {
  let size: PieceSize
  let color: PieceColor

  init(w: Int, h: Int, color: PieceColor) {
    self.size = PieceSize(w: w, h: h)
    self.color = color
  }

  init(size: PieceSize, color: PieceColor) {
    self.size = size
    self.color = color
  }

  var description: String {
    "\(size.description)'\(color.letter)'"
  }
}

struct PiecePool {
  var pieces:[PieceSize:[PieceColor]]
  var description: String {
    Array(pieces.keys).sorted(by:<).map{ key in
      let val = pieces[key]
      return key.description + ": [" + val!.map { $0.letter}.joined(separator: ", ") + "]"
    }.joined(separator: ", ")
  }

  mutating func removeFirstPiece(key:PieceSize) -> PuzzlePiece {
    let color = pieces[key]!.removeFirst()
    if pieces[key]!.isEmpty {
      pieces.removeValue(forKey: key)
    }
    return PuzzlePiece(size:key, color:color)
  }
}

enum GridError : Error {
  case outOfBounds(x: Int, y: Int)
  case filledCell(x: Int, y: Int)
}

struct Grid {
  let w = 7
  let h = 7
  var d = [UInt8](repeating: 0, count: 7*7)

  subscript(x: Int, y: Int) -> UInt8 {
      get {
        d[x+w*y]
      }
      set(newValue) {
          d[x+w*y] = newValue
      }
  }

  mutating func drop(piece: PuzzlePiece, x: Int, y: Int) throws {
    if x < 0 || y < 0 || (x + piece.size.w) > w || (y + piece.size.h) > h {
      throw GridError.outOfBounds(x: x, y: y)
    }
    for yy in 0..<piece.size.h {
      let yyy = y + yy
      for xx in 0..<piece.size.w {
        let xxx = x + xx
        if self[xxx,yyy] != 0 {
          throw GridError.filledCell(x: xxx, y: yyy)
        }
        self[xxx,yyy] = piece.color
      }
    }
  }

  var description: String {
    var result = ""
    for yy in 0..<h {
      for xx in 0..<w {
        let d = self[xx,yy]
        var c = Character(UnicodeScalar(32))
        if d > 0 {
          c = Character(UnicodeScalar(96 + d))
        }
        result += String(c)
      }
      result += "\n"
    }
    return result
  }
}

struct PuzzleNode {
  var grid: Grid
  var puzzlePieces: PiecePool

  var description: String {
    "\(grid.description)\n\(puzzlePieces.description)"
  }
}

func initialPuzzleState() -> PuzzleNode {
  var g = Grid()
  // stub out illegal spots
  for y in 5...6 {
    g[0,y] = 26
    g[1,y] = 26
    g[2,y] = 26
    g[4,y] = 26
    g[5,y] = 26
    g[6,y] = 26
  }

  // Place fixed piece
  let fixedPiece = PuzzlePiece(w:1, h:4, color: 12)
  try! g.drop(piece: fixedPiece, x: 3, y: 3)

  // Total pieces in puzzle:
  // 2x1 1,2
  // 3x1 3,4,5,6
  // 4x1 7
  // 1x3 8,9,10
  // 1x4 11,12 <-- 12 is special, fixed

  let piecePool = PiecePool(pieces: [
    PieceSize(w: 2, h: 1): [PieceColor]([1, 2]),
    PieceSize(w: 3, h: 1): [PieceColor]([3, 4, 5, 6]),
    PieceSize(w: 4, h: 1): [PieceColor]([7]),
    PieceSize(w: 1, h: 3): [PieceColor]([8, 9, 10]),
    PieceSize(w: 1, h: 4): [PieceColor]([11])
  ])

  return PuzzleNode(grid: g, puzzlePieces: piecePool)
}

func depthFirstSearch(node: PuzzleNode) -> Grid? {
  let keys = node.puzzlePieces.pieces.keys
  if keys.count == 0 {
    return node.grid
  }

  for key in keys {
    var newNode = node
    let piece = newNode.puzzlePieces.removeFirstPiece(key:key)
    let limitW = node.grid.w - piece.size.w
    let limitH = node.grid.h - piece.size.h
    for x in 0...limitW {
      for y in 0...limitH {
        do {
          var newNode2 = newNode
          try newNode2.grid.drop(piece: piece, x: x, y: y)
          if let result = depthFirstSearch(node:newNode2) {
            return result
          }
        } catch {
        }
      }
    }
  }
  return nil
}

func solve() {
  let node = initialPuzzleState()
  print(node.description)
  if let solution = dfs(node:node) {
    print(solution.description)
  } else {
    print("No solution found.")
  }
}

solve()
