const defaultNumbers = ["không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"];

function readThreeDigits(number, readZeroHundred) {
    let res = "";
    let hundred = Math.floor(number / 100);
    let ten = Math.floor((number % 100) / 10);
    let unit = number % 10;

    if (hundred > 0 || readZeroHundred) {
        res += defaultNumbers[hundred] + " trăm ";
    }

    if (ten > 0) {
        if (ten === 1) res += "mười ";
        else res += defaultNumbers[ten] + " mươi ";
    } else if (res !== "" && unit > 0) {
        res += "lẻ ";
    }

    if (unit > 0) {
        if (unit === 1 && ten > 1) res += "mốt ";
        else if (unit === 5 && ten > 0) res += "lăm ";
        else res += defaultNumbers[unit] + " ";
    }

    return res;
}

export function numberToVietnameseWords(number) {
    if (number === 0) return "Không đồng";
    if (number < 0) return "Âm " + numberToVietnameseWords(Math.abs(number));

    let res = "";
    let units = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ", "triệu tỷ"];
    let unitIdx = 0;

    while (number > 0) {
        let part = number % 1000;
        if (part > 0) {
            let partStr = readThreeDigits(part, number > 999);
            res = partStr + units[unitIdx] + " " + res;
        }
        number = Math.floor(number / 1000);
        unitIdx++;
    }

    res = res.trim();
    return res.charAt(0).toUpperCase() + res.slice(1) + " đồng chẵn";
}
