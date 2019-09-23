class Base64 {
    hidden [string]$_Base64

    Base64() { }
    Base64([string]$String) { $this.SetFromString($String) }
    Base64([Array]$Bytes) { $this.SetFromByte($Bytes) }

    SetFromString([string]$String) {
        $this._Base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($String))
    }
    SetFromByte([Array]$Bytes) {
        $this._Base64 = [Convert]::ToBase64String($Bytes)
    }
    Set([string]$String) {
        try {
            $null = [Convert]::FromBase64String($String)
            $this._Base64 = $String
        }
        catch {
            throw 'Not a valid Base64 string.'
        }
    }

    [string]GetString() {
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($this._Base64))
    }
    [string]ToString() {
        return $this._Base64
    }
}