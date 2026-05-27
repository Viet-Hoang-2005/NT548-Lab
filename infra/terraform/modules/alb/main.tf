resource "aws_lb" "alb" {
  name               = "group7-k3s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "group7-k3s-alb"
  }
}

resource "aws_lb_target_group" "k3s_tg" {
  name     = "group7-k3s-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }

  tags = {
    Name = "group7-k3s-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "workers" {
  count            = length(var.worker_instance_ids)
  target_group_arn = aws_lb_target_group.k3s_tg.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = 80
}
