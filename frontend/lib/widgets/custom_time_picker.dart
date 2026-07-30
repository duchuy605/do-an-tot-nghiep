import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  bool _isInputMode = false;
  
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minuteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    // Làm tròn phút về 0 hoặc 30
    _selectedMinute = widget.initialTime.minute >= 15 && widget.initialTime.minute < 45 ? 30 : 0;
    
    _hourController.text = _selectedHour.toString().padLeft(2, '0');
    _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
  }
  
  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isInputMode) {
      int h = int.tryParse(_hourController.text) ?? _selectedHour;
      int m = int.tryParse(_minuteController.text) ?? _selectedMinute;
      
      if (h < 6 || h > 22 || (h == 22 && m > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giờ hoạt động từ 06:00 đến 22:00.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (m != 0 && m != 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số phút chỉ có thể là 00 hoặc 30.'), backgroundColor: Colors.red),
        );
        return;
      }
      widget.onTimeSelected(TimeOfDay(hour: h, minute: m));
      Navigator.pop(context);
    } else {
      if (_selectedHour < 6 || _selectedHour > 22 || (_selectedHour == 22 && _selectedMinute > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giờ hoạt động từ 06:00 đến 22:00.'), backgroundColor: Colors.red),
        );
        return;
      }
      widget.onTimeSelected(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
      Navigator.pop(context);
    }
  }

  Widget _buildWheelPicker() {
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Picker Giờ
          SizedBox(
            width: 80,
            child: CupertinoPicker(
              itemExtent: 45,
              scrollController: FixedExtentScrollController(initialItem: _selectedHour - 6 >= 0 ? _selectedHour - 6 : 0),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedHour = index + 6;
                });
              },
              children: List.generate(17, (index) {
                final h = index + 6;
                return Center(
                  child: Text(h.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                );
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          // Picker Phút (Chỉ 00 và 30)
          SizedBox(
            width: 80,
            child: CupertinoPicker(
              itemExtent: 45,
              scrollController: FixedExtentScrollController(initialItem: _selectedMinute == 30 ? 1 : 0),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedMinute = index == 0 ? 0 : 30;
                });
              },
              children: const [
                Center(child: Text('00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500))),
                Center(child: Text('30', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPicker() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: _hourController,
                focusNode: _hourFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                maxLength: 2,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF8225), width: 2)),
                ),
                onChanged: (val) {
                  if (val.length == 2) _minuteFocus.requestFocus();
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _minuteController,
                focusNode: _minuteFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                maxLength: 2,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF8225), width: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Text('Chọn giờ bắt đầu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _submit,
                child: const Text('Xong', style: TextStyle(color: orangeColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: _isInputMode ? 'Chuyển sang cuộn' : 'Chuyển sang bàn phím',
                  icon: Icon(_isInputMode ? Icons.view_day_rounded : Icons.keyboard_alt_outlined, color: orangeColor),
                  onPressed: () {
                    setState(() {
                      _isInputMode = !_isInputMode;
                      if (_isInputMode) {
                        _hourController.text = _selectedHour.toString().padLeft(2, '0');
                        _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          _isInputMode ? _buildInputPicker() : _buildWheelPicker(),
          // Bù khoảng trống cho bàn phím ảo
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
