variable "vpc_id" {
    type = string
    description = "vpc id"
    default = ""
}
variable "private_subnets" {
    type = list(string)
    description = "private subnet"
    default = []
}
