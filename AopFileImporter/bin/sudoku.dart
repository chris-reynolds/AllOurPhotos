/*
  Created by chrisreynolds on 2019-07-09
  
  Purpose: playing

*/

const z08 = [0,1,2,3,4,5,6,7,8];
const z19 = [1,2,3,4,5,6,7,8,9];
const z02 = [0,1,2];

var gridNos = [
  [7, 0, 0, 8, 0, 6, 0, 0, 0],
  [3, 0, 0, 9, 2, 0, 0, 0, 0],
  [0, 0, 0, 7, 0, 5, 1, 0, 0,],
  [9, 6, 0, 0, 0, 8, 0, 0, 2],
  [0, 8, 0, 0, 0, 0, 0, 5, 0],
  [5, 0, 0, 4, 0, 0, 0, 7, 9],
  [0, 0, 2, 5, 0, 9, 0, 0, 0],
  [0, 0, 0, 0, 7, 3, 0, 0, 5],
  [0, 0, 0, 2, 0, 0, 0, 0, 5],
];

class Cell {
  int row;
  int col;
  List<int> possibles = [];
  Cell(this.row,this.col) {
    possibles.addAll(z19);
  }
  get value => gridNos[row][col];
  set value(int x) {
    gridNos[row][col] = x;
  }

  int hashCode() => this.row*1000 + this.col;

  bool operator ==(o) => (this.row==o.row  && this.col==o.col );
  List<Block> get cellBlocks {
    List<Block> result = [];
    result.add(blocks[row]);
    result.add(blocks[9+col]);
    int blockNo = 18+(row ~/ 3)*3 +(col ~/ 3);
    Block crossBlock = blocks[blockNo];
    result.add(crossBlock);
    if (crossBlock.cells.indexOf(this)<0)
      print('blah');
    return result;
  }
}

List<Cell> makeCells() {
  List<Cell> result = [];
  for (int r in z08)
    for (int c in z08)
      result.add(Cell(r,c));
  return result;
} // of makeCells
List<Cell>cells = makeCells();
Cell cell(int r,int c) => cells[r*9+c];

List<Block> blocks = makeBlocks();

class Block {
  String name;
  Block(this.name);
  List<Cell> cells =[];
}

List<Block> makeBlocks() {
  List<Block> blocks = [];
  // make columns
  for (int c in z08) {
    Block newBlock = Block('Column $c');
    for (int r in z08)
      newBlock.cells.add(cell(r,c));
    blocks.add(newBlock);
  }
  // make rows
  for (int r in z08) {
    Block newBlock = Block('Row $r');
    for (int c in z08)
      newBlock.cells.add(cell(r,c));
    blocks.add(newBlock);
  }
  for (int rr in z02)
    for (int cc in z02) {
      Block newBlock = Block('Square $rr - $cc');
      for (int r in z02)
        for (int c in z02)
          newBlock.cells.add(cell(rr*3+r,cc*3+c));
      blocks.add(newBlock);
    }
  return blocks;
} // of makeBlocks



void main() {

  for (int r in z08)
    for (int c in z08)
      print('$r $c ${cell(r,c).cellBlocks.length} ${cell(r,c).possibles.length}');

} // of main

