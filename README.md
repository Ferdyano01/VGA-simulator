### VGA Simulator

VGA Simulator merupakan sebuah perangkat simulasi yang akan melakukan operasi decoding pada suatu file input berupa HEX yang berisi data-data pixel dan akan menghasilkan output berupa frame-frame dalam bentuk PPM. Lalu kita akan menyusun kembali (assembly) semua file PPM itu dengan menggunakan script python yang sudah ditulis.

### Required Softwares & Libraries

Untuk menjalankan kode VHDL ini, kita membutuhkan beberapa software:

- Python (dengan library seperti cv2 dan numpy).
- HDL simulator seperti Vivado atau ModelSim/QuestaSim.

### Input File Processing

Sebelum memulai menjalankan video, kita bisa mendapatkan input file HEX dengan melakukan konversi dari MP4 ke HEX dengan menggunakan script python yang sudah disediakan pada folder Python Helper, di dalamnya terdapat berkas MP4toHEX.py yang dapat kita jalankan, sebelumnya kita konfigurasikan terlebih dahulu script tersebut dengan mengganti argumen input file:

<img width="811" height="100" alt="Pasted image 20251207174912" src="https://github.com/user-attachments/assets/6a92283f-f17e-4dcf-9156-3ecfd7a4d459" />

Pada file tersebut, inputnya adalah 'bad-apple.mp4' tanpa tanda petik, jika kita memiliki nama file yang berbeda, ubah saja argumen tersebut sesuai dengan nama file yang akan diproses dan letakkan file video tersebut dalam direktori yang sama dengen script python tersebut.

Lalu juga ada konfigurasi frame, atur saja sesuai dengan jumlah frame yang ingin kita proses, untuk mengetahui dan menghitung frame video, kita bisa menggunakan web application seperti https://somewes.com/frame-count/

<img width="901" height="148" alt="Pasted image 20251207175945" src="https://github.com/user-attachments/assets/aa675ab8-13ad-4dbc-b74d-151382468cad" />

Setelah kita selesai melakukan konfigurasi, kita jalankan saja script tersebut dengan menggunakan python. Output dari script tersebut akan menghasilkan file berupa data HEX dengan nama 'image_data.hex' yang akan menjadi input terhadap program VHDL yang akan kita jalankan.
### VHDL Simulation

Lalu kita jalankan simulasi VHDL, jangan lupa ubah direktori dalam kode testbench pada 'tb_bad_apple.vhd' pada "constant FILE_LOCATION" sesuai dengan direktori, untuk memudahkan bisa pindahkan input hex tersebut ke direktori yang sama dengan kode testbench dan menyesuaikannya seperti ini, sehingga simulator bisa memproses input dalam direktori yang sama:

<img width="895" height="51" alt="Pasted image 20251207181452" src="https://github.com/user-attachments/assets/a8c0b4c4-26f4-4d0a-8b13-c6e874b25f2b" />

Setelah selesai, kita bisa jalankan simulasi dan stop sampai frame sudah sampai pada yang ditentukan, atau kita juga bisa menyesuaikan waktu run berdasarkan perhitungan frame.

<img width="592" height="180" alt="Pasted image 20251207181843" src="https://github.com/user-attachments/assets/6bcf214d-0460-48f9-b530-07af0ff2d15b" />

### Output File Processing

Setelah selesai memproses, simulasi VHDL akan menghasilkan file-file PPM seperti ini:

<img width="1126" height="694" alt="Pasted image 20251207182032" src="https://github.com/user-attachments/assets/ba13f753-315d-4eda-b40d-3dc15dfc15ad" />

Lalu kita akan melakukan assembly dengan menggunakan script python pada folder Python Helper yaitu 'PPMtoMP4.py', kita letakkan saja file-file PPM itu dalam satu direktori yang sama dengan script tersebut dan jalankan script tersebut dengan menggunakan python. Output dari script tersebut akan menghasilkan video dengan format MP4 dengan nama "simulated_video.mp4".

Contoh hasil dari simulasi videonya bisa dilihat di bawah ini:

[![Result](https://img.youtube.com/vi/_vS-kSauPwM/0.jpg)](https://www.youtube.com/watch?v=_vS-kSauPwM)
