


class CardCalculator{


  int _point = 0;

  /*
  state
  0 = 辨識牌
  1 = 下注
  出現 莊勝或是閒勝時候 切換state = 0
  計算完再下注期間進行操作
   */
  int _state = 0;

  var pointMap = <int,int>{
    1:1,
    2:1,
    3:2,
    4:3,
    5:-2,
    6:-2,
    7:-2,
    8:-1,
    9:0,
    10:0,
    11:0,
    12:0,
    13:0,
  };

  CardCalculator();

  void insertCard(List cardList){
    for(var card in cardList){
      _point += pointMap[card]!;
    }
  }

  bool bar(){
    if(_point>0){
      return true;
    }
    return false;
  }

  void refreshState(int state){
    _state =state;
  }

  void bet(){
    if(_state == 1){
    //  do bet operation
    }
  }
  void reset(){
    _point = 0;
  }
}
