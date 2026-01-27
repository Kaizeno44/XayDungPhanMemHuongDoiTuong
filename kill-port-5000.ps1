# Script PowerShell để kill process đang chiếm port 5000
Write-Host "Đang kiểm tra port 5000..." -ForegroundColor Yellow

# Tìm process đang dùng port 5000
$process = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($process) {
    Write-Host "Tìm thấy process đang chiếm port 5000:" -ForegroundColor Red
    foreach ($pid in $process) {
        $procInfo = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($procInfo) {
            Write-Host "  PID: $pid - Process: $($procInfo.ProcessName) - Path: $($procInfo.Path)" -ForegroundColor Cyan
        }
    }
    
    Write-Host "`nBạn có muốn kill các process này không? (Y/N)" -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        foreach ($pid in $process) {
            try {
                Stop-Process -Id $pid -Force
                Write-Host "Đã kill process PID: $pid" -ForegroundColor Green
            } catch {
                Write-Host "Không thể kill process PID: $pid - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "`nPort 5000 đã được giải phóng!" -ForegroundColor Green
    } else {
        Write-Host "Đã hủy." -ForegroundColor Yellow
    }
} else {
    Write-Host "Không có process nào đang chiếm port 5000." -ForegroundColor Green
}

Write-Host "`nNhấn phím bất kỳ để thoát..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
